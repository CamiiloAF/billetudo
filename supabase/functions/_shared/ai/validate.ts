// Request parsing and proposal validation.
//
// Everything the model produces is treated as hostile until proven otherwise:
// ids that do not exist, negative amounts, four-letter currencies, dates in
// 1970, major units where minor units belong. A bad proposal is answered back
// to the model so it can correct itself — it never reaches the app, because on
// the app side it would render as a card the user might tap.

import { AiHttpError } from '../errors.ts';
import { AiMessage, AiToolCall } from './types.ts';

export const PROTOCOL_VERSION = 1;

/// Anything below this in minor units is almost certainly the model writing
/// major units by mistake: 450 would be 4.50 in a currency with cents, which no
/// real budget or goal ever is. Rejecting it is how a budget 100x too small
/// gets caught before it becomes a card.
const MIN_PLAUSIBLE_AMOUNT_MINOR = 100;

/// Roughly 1990-01-01 to 2100-01-01, in unix seconds.
const MIN_DATE_SECONDS = 631152000;
const MAX_DATE_SECONDS = 4102444800;

const MAX_MESSAGES = 40;

export interface ChatRequest {
  conversationId: string;
  locale: string;
  timezone: string;
  clientVersion: string;
  /// Whether the device is sending free-text notes inside `snapshot` and tool
  /// results. Off by default and on ONLY if the person turned the setting on.
  ///
  /// The server never decides this and cannot verify it — the device is the
  /// only party that can withhold a note, and it already did (or did not)
  /// before this request was built. This flag exists purely so the prompt can
  /// tell the model the truth about what it is looking at: claiming notes
  /// never travel while they sit in the snapshot makes the model distrust
  /// data it can plainly see. Absent means off, so an older client that does
  /// not send it gets the conservative wording.
  notesAccessEnabled: boolean;
  snapshot: Record<string, unknown>;
  messages: AiMessage[];
}

export function parseChatRequest(body: unknown): ChatRequest {
  if (typeof body !== 'object' || body === null) {
    throw new AiHttpError('invalid_request', 'body must be an object');
  }
  const raw = body as Record<string, unknown>;

  const protocol = raw.protocolVersion;
  if (protocol !== undefined && protocol !== PROTOCOL_VERSION) {
    throw new AiHttpError(
      'unsupported_protocol',
      `this server speaks protocol ${PROTOCOL_VERSION}`,
    );
  }

  const messages = raw.messages;
  if (!Array.isArray(messages) || messages.length === 0) {
    throw new AiHttpError('invalid_request', 'messages must be a non-empty array');
  }
  if (messages.length > MAX_MESSAGES) {
    throw new AiHttpError('payload_too_large', 'transcript too long');
  }

  const snapshot = raw.snapshot;
  if (typeof snapshot !== 'object' || snapshot === null || Array.isArray(snapshot)) {
    throw new AiHttpError('invalid_request', 'snapshot must be an object');
  }

  return {
    conversationId: asString(raw.conversationId) ?? '',
    locale: asString(raw.locale) ?? 'es',
    timezone: asString(raw.timezone) ?? 'UTC',
    clientVersion: asString(raw.clientVersion) ?? '',
    notesAccessEnabled: raw.notesAccessEnabled === true,
    snapshot: snapshot as Record<string, unknown>,
    messages: messages.map(parseMessage),
  };
}

function parseMessage(raw: unknown, index: number): AiMessage {
  if (typeof raw !== 'object' || raw === null) {
    throw new AiHttpError('invalid_request', `messages[${index}] must be an object`);
  }
  const value = raw as Record<string, unknown>;
  const role = value.role;
  if (role !== 'user' && role !== 'assistant' && role !== 'tool') {
    throw new AiHttpError('invalid_request', `messages[${index}].role is invalid`);
  }

  const toolCalls = Array.isArray(value.toolCalls)
    ? value.toolCalls.map(parseToolCall)
    : undefined;

  return {
    role,
    content: asString(value.content),
    toolCalls,
    toolCallId: asString(value.toolCallId),
    name: asString(value.name),
    result: value.result,
  };
}

function parseToolCall(raw: unknown): AiToolCall {
  const value = (raw ?? {}) as Record<string, unknown>;
  return {
    id: asString(value.id) ?? '',
    name: asString(value.name) ?? '',
    arguments: (typeof value.arguments === 'object' && value.arguments !== null)
      ? value.arguments as Record<string, unknown>
      : {},
    // Opaque passthrough — the client only ever echoes back what a previous
    // response gave it. Absent for any turn that predates this field or that
    // the client rebuilt itself (see `ai_repository_impl.dart`'s known gap).
    thoughtSignature: asString(value.thoughtSignature),
  };
}

/// How many `tool` messages sit after the last `user` message. This is the only
/// place a runaway read loop can be detected, because each read round arrives
/// as a fresh HTTP request with no server-side memory of the previous one.
export function toolRoundsSinceLastUser(messages: AiMessage[]): number {
  let rounds = 0;
  for (let i = messages.length - 1; i >= 0; i--) {
    const role = messages[i].role;
    if (role === 'user') break;
    if (role === 'tool') rounds++;
  }
  return rounds;
}

// ---------------------------------------------------------------------------
// Proposal validation
// ---------------------------------------------------------------------------

export interface SnapshotIndex {
  currencies: Set<string>;
  ids: Set<string>;
}

/// Collects every `id` and every `currency` anywhere in the snapshot, at any
/// depth. Walking the tree rather than reading known paths means the index
/// keeps working when the client adds a section — and an id the model quotes
/// is only ever accepted if the client itself put it there.
export function indexSnapshot(snapshot: Record<string, unknown>): SnapshotIndex {
  const currencies = new Set<string>();
  const ids = new Set<string>();

  const visit = (node: unknown): void => {
    if (Array.isArray(node)) {
      node.forEach(visit);
      return;
    }
    if (typeof node !== 'object' || node === null) return;

    for (const [key, value] of Object.entries(node)) {
      if (typeof value === 'string') {
        if (key === 'id' || key.endsWith('Id')) ids.add(value);
        if (key === 'currency' || key === 'code') currencies.add(value);
      } else {
        visit(value);
      }
    }
  };

  visit(snapshot);
  return { currencies, ids };
}

export interface ProposalValidation {
  ok: boolean;
  reason?: string;
  payload?: Record<string, unknown>;
}

/// Proposals that carry no amount of their own, and so are exempt from the
/// currency check every other proposal must pass. A category has no money at
/// all; linking an existing movement to a debt does not introduce any either —
/// the amount and currency already live on that movement, and asking the model
/// to restate them would only invite it to restate them wrong.
const MONEYLESS_PROPOSALS = new Set([
  'propose_create_category',
  'propose_link_transaction_to_debt',
]);

export function validateProposal(
  toolName: string,
  args: Record<string, unknown>,
  index: SnapshotIndex,
): ProposalValidation {
  const rationale = asString(args.rationale);
  if (!rationale) {
    return fail('falta "rationale": explica en una frase de donde sale la propuesta');
  }

  const currency = asString(args.currency);
  if (!MONEYLESS_PROPOSALS.has(toolName)) {
    if (!currency || !/^[A-Z]{3}$/.test(currency)) {
      return fail('"currency" debe ser un codigo ISO 4217 de 3 letras mayusculas');
    }
    if (index.currencies.size > 0 && !index.currencies.has(currency)) {
      return fail(
        `la moneda ${currency} no aparece en el resumen; usa una de las que si estan`,
      );
    }
  }

  switch (toolName) {
    case 'propose_create_budget': {
      const amount = checkAmount(args.amountMinor);
      if (amount.reason) return fail(amount.reason);
      const name = asString(args.name);
      if (!name) return fail('falta "name"');
      const period = asString(args.period);
      if (!period || !['weekly', 'biweekly', 'monthly', 'yearly'].includes(period)) {
        return fail('"period" debe ser weekly, biweekly, monthly o yearly');
      }
      return {
        ok: true,
        payload: {
          name,
          amountMinor: amount.value,
          currency,
          period,
          // Hallucinated ids are dropped rather than failing the whole
          // proposal: a budget with a broader scope than intended is something
          // the user can see on the card and fix, an error is a dead end.
          categoryIds: keepKnownIds(args.categoryIds, index),
          accountIds: keepKnownIds(args.accountIds, index),
          rationale,
        },
      };
    }

    case 'propose_create_goal': {
      const amount = checkAmount(args.targetMinor);
      if (amount.reason) return fail(amount.reason);
      const name = asString(args.name);
      if (!name) return fail('falta "name"');
      const targetDate = optionalDate(args.targetDate);
      if (targetDate.reason) return fail(targetDate.reason);
      const accountId = asString(args.accountId);
      return {
        ok: true,
        payload: {
          name,
          targetMinor: amount.value,
          currency,
          targetDate: targetDate.value,
          accountId: accountId && index.ids.has(accountId) ? accountId : undefined,
          rationale,
        },
      };
    }

    case 'propose_create_category': {
      const name = asString(args.name);
      if (!name) return fail('falta "name"');
      const kind = asString(args.kind);
      if (kind !== 'income' && kind !== 'expense') {
        return fail('"kind" debe ser income o expense');
      }
      const parentId = asString(args.parentId);
      if (parentId && !index.ids.has(parentId)) {
        return fail(`la categoria padre ${parentId} no existe en el resumen`);
      }
      return { ok: true, payload: { name, kind, parentId, rationale } };
    }

    case 'propose_create_transaction': {
      const amount = checkAmount(args.amountMinor);
      if (amount.reason) return fail(amount.reason);
      const type = asString(args.type);
      if (type !== 'income' && type !== 'expense') {
        return fail('"type" debe ser income o expense');
      }
      const date = optionalDate(args.date);
      if (date.reason) return fail(date.reason);
      if (date.value === undefined) return fail('falta "date"');

      // An account id is not droppable the way a budget scope is: a movement
      // has to land somewhere, and guessing which account would be worse than
      // asking the model to try again.
      const accountId = asString(args.accountId);
      if (!accountId || !index.ids.has(accountId)) {
        return fail('"accountId" debe ser el id de una cuenta que este en el resumen');
      }
      const categoryId = asString(args.categoryId);
      if (categoryId && !index.ids.has(categoryId)) {
        return fail(`la categoria ${categoryId} no existe en el resumen`);
      }
      // Optional: when present the movement is born attributed to the debt, so
      // the person confirms once instead of twice. Refused rather than dropped
      // if unknown — silently unlinking a movement the model said would count
      // against a debt is a lie the confirmation card would then tell.
      const debtId = asString(args.debtId);
      if (debtId && !index.ids.has(debtId)) {
        return fail(`la deuda ${debtId} no existe en el resumen`);
      }

      return {
        ok: true,
        payload: {
          type,
          amountMinor: amount.value,
          currency,
          date: date.value,
          accountId,
          categoryId,
          debtId,
          note: asString(args.note),
          rationale,
        },
      };
    }

    case 'propose_link_transaction_to_debt': {
      // Both ids must have travelled from the device: `transactionId` comes
      // from a `get_transactions` result, `debtId` from the snapshot. This
      // index is flat (every id at any depth), so it proves the client sent
      // the value, not that it is of the right kind — the device re-checks
      // both when it applies the proposal, and `LinkTransactionToDebt` is the
      // one that refuses a closed debt.
      const transactionId = asString(args.transactionId);
      if (!transactionId || !index.ids.has(transactionId)) {
        return fail(
          '"transactionId" debe ser el id de un movimiento que hayas obtenido '
            + 'con get_transactions',
        );
      }
      const debtId = asString(args.debtId);
      if (!debtId || !index.ids.has(debtId)) {
        return fail('"debtId" debe ser el id de una deuda que este en el resumen');
      }
      return { ok: true, payload: { transactionId, debtId, rationale } };
    }

    default:
      return fail(`herramienta desconocida: ${toolName}`);
  }
}

function checkAmount(raw: unknown): { value?: number; reason?: string } {
  if (typeof raw !== 'number' || !Number.isFinite(raw)) {
    return { reason: 'el monto debe ser un numero entero en unidades menores' };
  }
  // A model that answers 4500.0 meant an integer; one that answers 4500.5 was
  // thinking in major units. The first is coerced, the second is refused.
  if (!Number.isInteger(raw)) {
    return { reason: 'el monto debe ser un entero en unidades menores (centavos)' };
  }
  if (raw <= 0) {
    return { reason: 'el monto debe ser positivo' };
  }
  if (raw < MIN_PLAUSIBLE_AMOUNT_MINOR) {
    return {
      reason:
        'el monto parece estar en unidades mayores; recuerda que 45.000 se '
        + 'escribe 4500000 en unidades menores',
    };
  }
  return { value: raw };
}

function optionalDate(raw: unknown): { value?: number; reason?: string } {
  if (raw === undefined || raw === null) return {};
  if (typeof raw !== 'number' || !Number.isInteger(raw)) {
    return { reason: 'las fechas son timestamps unix enteros en SEGUNDOS' };
  }
  if (raw < MIN_DATE_SECONDS || raw > MAX_DATE_SECONDS) {
    return {
      reason:
        'la fecha esta fuera de rango; recuerda que son SEGUNDOS unix, no '
        + 'milisegundos',
    };
  }
  return { value: raw };
}

function keepKnownIds(raw: unknown, index: SnapshotIndex): string[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((value): value is string => typeof value === 'string')
    .filter((value) => index.ids.has(value));
}

function fail(reason: string): ProposalValidation {
  return { ok: false, reason };
}

function asString(raw: unknown): string | undefined {
  return typeof raw === 'string' && raw.length > 0 ? raw : undefined;
}
