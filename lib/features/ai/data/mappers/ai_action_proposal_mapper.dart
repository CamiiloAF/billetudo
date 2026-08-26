import '../../../budgets/domain/entities/budget.dart' show BudgetPeriod;
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../transactions/domain/entities/transaction.dart'
    show TransactionType;
import '../../domain/entities/ai_action_proposal.dart';

/// JSON ↔ [AiActionProposal]. **The trust boundary with the model.**
///
/// Two different hostile inputs meet here and are treated identically:
///
///  1. What the broker just sent. The Edge Function already validated it
///     (`supabase/functions/_shared/ai/validate.ts`), but a client that trusts
///     a server-side check it cannot see is a client that renders a card the
///     user may tap — so every rule is re-applied here.
///  2. What this device persisted months ago. `proposalsJson` is stored
///     verbatim, so an old thread carries whatever the contract looked like
///     back then, and the contract is expected to grow.
///
/// From both, the single hard guarantee: **[fromJson] never throws.** An
/// unknown `kind`, a malformed payload, a negative amount, a four-letter
/// currency, an impossible date, a missing required field, a field of the
/// wrong type — all of them degrade to [UnsupportedProposal], which renders as
/// plain text with no confirm button. Throwing instead would take down the
/// whole screen when the user opens an old conversation.
///
/// [toJson] round-trips: `toJson(fromJson(x))` parses back to the same value,
/// which is what lets a card's status survive a relaunch.
abstract final class AiActionProposalMapper {
  /// Mirrors `MIN_PLAUSIBLE_AMOUNT_MINOR` in `validate.ts`. Anything under a
  /// hundred minor units is almost certainly the model writing major units by
  /// mistake, and a budget 100x too small is worse than no budget.
  static const int _minAmountMinor = 100;

  /// Roughly 1990-01-01 and 2100-01-01 in unix **seconds**, same bounds the
  /// server enforces. The range is what catches milliseconds sent as seconds,
  /// which would otherwise land the user ~50 000 years out.
  static const int _minDateSeconds = 631152000;
  static const int _maxDateSeconds = 4102444800;

  static const String _kindBudget = 'create_budget';
  static const String _kindGoal = 'create_goal';
  static const String _kindCategory = 'create_category';
  static const String _kindTransaction = 'create_transaction';

  /// Parses one wire/stored proposal. Never throws — see the class doc.
  static AiActionProposal fromJson(Map<String, Object?> json) {
    // The outer catch is belt and braces on top of the per-field guards
    // below: the guarantee this mapper makes is absolute, so it must not
    // depend on having enumerated every way a `Map` can misbehave.
    try {
      return _fromJson(json);
    } on Object {
      return UnsupportedProposal(
        id: _string(json['id']) ?? '',
        title: _string(json['title']) ?? '',
        status: _status(json['status']),
        rawKind: _string(json['kind']) ?? '',
      );
    }
  }

  /// Parses a `proposals` array from any shape. A non-list (or a list holding
  /// non-objects) yields no proposals rather than an error: the bubble's text
  /// is still worth showing.
  static List<AiActionProposal> fromJsonList(Object? raw) {
    if (raw is! List) {
      return const <AiActionProposal>[];
    }
    return <AiActionProposal>[
      for (final item in raw)
        if (_object(item) case final Map<String, Object?> json) fromJson(json),
    ];
  }

  static AiActionProposal _fromJson(Map<String, Object?> json) {
    final id = _string(json['id']) ?? '';
    final title = _string(json['title']) ?? '';
    final rawKind = _string(json['kind']) ?? '';
    final status = _status(json['status']);
    final payload = _object(json['payload']) ?? const <String, Object?>{};

    final parsed = switch (rawKind) {
      _kindBudget => _budget(id, title, status, payload),
      _kindGoal => _goal(id, title, status, payload),
      _kindCategory => _category(id, title, status, payload),
      _kindTransaction => _transaction(id, title, status, payload),
      _ => null,
    };

    return parsed ??
        UnsupportedProposal(
          id: id,
          title: title,
          status: status,
          rawKind: rawKind,
        );
  }

  /// The wire shape (`{id, kind, title, payload}`) plus `status`.
  ///
  /// `status` is an app-side addition the server never sends, and its absence
  /// parses back as [AiProposalStatus.pending] — so a freshly received
  /// proposal and a re-read of what we wrote agree.
  static Map<String, Object?> toJson(AiActionProposal proposal) =>
      <String, Object?>{
        'id': proposal.id,
        'kind': _kindOf(proposal),
        'title': proposal.title,
        'status': proposal.status.name,
        // An UnsupportedProposal has no payload to write back: the entity
        // keeps only `rawKind`, so a round-trip through this app drops the
        // fields it could not read anyway. It still re-parses as the same
        // UnsupportedProposal, which is the invariant that matters.
        if (_payloadOf(proposal) case final Map<String, Object?> payload)
          'payload': payload,
      };

  static String _kindOf(AiActionProposal proposal) => switch (proposal) {
        CreateBudgetProposal() => _kindBudget,
        CreateGoalProposal() => _kindGoal,
        CreateCategoryProposal() => _kindCategory,
        CreateTransactionProposal() => _kindTransaction,
        UnsupportedProposal(:final rawKind) => rawKind,
      };

  static Map<String, Object?>? _payloadOf(AiActionProposal proposal) =>
      switch (proposal) {
        CreateBudgetProposal() => <String, Object?>{
            'name': proposal.name,
            'amountMinor': proposal.amountMinor,
            'currency': proposal.currency,
            'period': proposal.period.name,
            'startDate': _toUnixSeconds(proposal.startDate),
            'recurring': proposal.recurring,
            'categoryIds': proposal.categoryIds.toList(),
            'accountIds': proposal.accountIds.toList(),
          },
        CreateGoalProposal() => <String, Object?>{
            'name': proposal.name,
            'targetMinor': proposal.targetMinor,
            'currency': proposal.currency,
            if (proposal.targetDate case final DateTime date)
              'targetDate': _toUnixSeconds(date),
            if (proposal.accountId case final String accountId)
              'accountId': accountId,
          },
        CreateCategoryProposal() => <String, Object?>{
            'name': proposal.name,
            'kind': proposal.kind.name,
            if (proposal.parentId case final String parentId)
              'parentId': parentId,
          },
        CreateTransactionProposal() => <String, Object?>{
            'accountId': proposal.accountId,
            'amountMinor': proposal.amountMinor,
            'currency': proposal.currency,
            'type': proposal.type.name,
            'date': _toUnixSeconds(proposal.date),
            if (proposal.categoryId case final String categoryId)
              'categoryId': categoryId,
            if (proposal.note case final String note) 'note': note,
          },
        UnsupportedProposal() => null,
      };

  // -------------------------------------------------------------------------
  // Per-kind parsing. Each returns null when the payload is not usable, which
  // the caller turns into an UnsupportedProposal.
  // -------------------------------------------------------------------------

  static CreateBudgetProposal? _budget(
    String id,
    String title,
    AiProposalStatus status,
    Map<String, Object?> payload,
  ) {
    final name = _string(payload['name']);
    final amountMinor = _amountMinor(payload['amountMinor']);
    final currency = _currency(payload['currency']);
    final period = _period(payload['period']);
    if (name == null ||
        amountMinor == null ||
        currency == null ||
        period == null) {
      return null;
    }
    return CreateBudgetProposal(
      id: id,
      title: title,
      status: status,
      name: name,
      amountMinor: amountMinor,
      currency: currency,
      period: period,
      // The write tool has no `startDate`/`recurring` argument today (see
      // `validate.ts`), while the entity requires both. Defaulting to "starts
      // today, keeps recurring" matches what a budget the user is being
      // offered means, and is what `BudgetDraft` would default to anyway. It
      // is written back by [toJson], so the anchor is stable from the first
      // parse on instead of drifting a day every time the card is re-read.
      startDate: _date(payload['startDate']) ?? _today(),
      recurring: _bool(payload['recurring']) ?? true,
      // Unknown ids are dropped, never fatal: the server already filters them
      // against the snapshot, and `ExecuteAiAction` filters again. A scope
      // that ended up broader than intended is visible on the card.
      categoryIds: _stringSet(payload['categoryIds']),
      accountIds: _stringSet(payload['accountIds']),
    );
  }

  static CreateGoalProposal? _goal(
    String id,
    String title,
    AiProposalStatus status,
    Map<String, Object?> payload,
  ) {
    final name = _string(payload['name']);
    final targetMinor = _amountMinor(payload['targetMinor']);
    final currency = _currency(payload['currency']);
    if (name == null || targetMinor == null || currency == null) {
      return null;
    }
    return CreateGoalProposal(
      id: id,
      title: title,
      status: status,
      name: name,
      targetMinor: targetMinor,
      currency: currency,
      // Optional: an out-of-range date degrades to "no deadline" rather than
      // killing an otherwise good goal.
      targetDate: _date(payload['targetDate']),
      accountId: _string(payload['accountId']),
    );
  }

  static CreateCategoryProposal? _category(
    String id,
    String title,
    AiProposalStatus status,
    Map<String, Object?> payload,
  ) {
    final name = _string(payload['name']);
    final kind = _categoryKind(payload['kind']);
    if (name == null || kind == null) {
      return null;
    }
    return CreateCategoryProposal(
      id: id,
      title: title,
      status: status,
      name: name,
      kind: kind,
      parentId: _string(payload['parentId']),
    );
  }

  static CreateTransactionProposal? _transaction(
    String id,
    String title,
    AiProposalStatus status,
    Map<String, Object?> payload,
  ) {
    final accountId = _string(payload['accountId']);
    final amountMinor = _amountMinor(payload['amountMinor']);
    final currency = _currency(payload['currency']);
    final type = _transactionType(payload['type']);
    final date = _date(payload['date']);
    // Unlike a budget's scope, none of these is droppable: a movement with no
    // account, no amount or no date is not a movement, and guessing any of
    // them would be the fabrication this whole layer exists to prevent.
    if (accountId == null ||
        amountMinor == null ||
        currency == null ||
        type == null ||
        date == null) {
      return null;
    }
    return CreateTransactionProposal(
      id: id,
      title: title,
      status: status,
      accountId: accountId,
      amountMinor: amountMinor,
      currency: currency,
      type: type,
      date: date,
      categoryId: _string(payload['categoryId']),
      note: _string(payload['note']),
    );
  }

  // -------------------------------------------------------------------------
  // Field readers. All total: they answer null instead of throwing.
  // -------------------------------------------------------------------------

  static String? _string(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;

  static bool? _bool(Object? raw) => raw is bool ? raw : null;

  static Map<String, Object?>? _object(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    // `jsonDecode` hands back `Map<String, dynamic>`, and Supabase's client
    // can hand back a plain `Map`. Re-key rather than reject.
    if (raw is Map) {
      return <String, Object?>{
        for (final entry in raw.entries) '${entry.key}': entry.value,
      };
    }
    return null;
  }

  /// A positive integer of minor units, at or above [_minAmountMinor].
  ///
  /// A whole `double` (`4500.0`, which is what JSON gives back for an integer
  /// literal on some paths) is accepted; a fractional one is refused, because
  /// `4500.5` means the model was thinking in major units.
  static int? _amountMinor(Object? raw) {
    final value = switch (raw) {
      final int value => value,
      final double value
          when value.isFinite && value == value.roundToDouble() =>
        value.toInt(),
      _ => null,
    };
    if (value == null || value < _minAmountMinor) {
      return null;
    }
    return value;
  }

  /// An ISO 4217 code: exactly three uppercase letters. Nothing is upcased on
  /// the way in — a lowercase code means the model improvised, and improvised
  /// currencies are how a COP figure ends up labelled USD.
  static String? _currency(Object? raw) {
    final value = _string(raw);
    if (value == null || !RegExp(r'^[A-Z]{3}$').hasMatch(value)) {
      return null;
    }
    return value;
  }

  /// Unix **seconds** to a local [DateTime]. Out-of-range (i.e. milliseconds)
  /// answers null.
  static DateTime? _date(Object? raw) {
    if (raw is! int || raw < _minDateSeconds || raw > _maxDateSeconds) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(
      raw * Duration.millisecondsPerSecond,
    );
  }

  static int _toUnixSeconds(DateTime date) =>
      date.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// `custom` is refused on purpose: a custom period needs an explicit end
  /// date that the write tool has no argument for, so accepting it would
  /// produce a budget with an undefined window.
  static BudgetPeriod? _period(Object? raw) => switch (_string(raw)) {
        'weekly' => BudgetPeriod.weekly,
        'biweekly' => BudgetPeriod.biweekly,
        'monthly' => BudgetPeriod.monthly,
        'yearly' => BudgetPeriod.yearly,
        _ => null,
      };

  static CategoryKind? _categoryKind(Object? raw) => switch (_string(raw)) {
        'income' => CategoryKind.income,
        'expense' => CategoryKind.expense,
        _ => null,
      };

  /// `transfer` is not proposable — it needs a destination account the model
  /// has no way to disambiguate — so it is not accepted here either.
  static TransactionType? _transactionType(Object? raw) =>
      switch (_string(raw)) {
        'income' => TransactionType.income,
        'expense' => TransactionType.expense,
        _ => null,
      };

  /// Unknown status → [AiProposalStatus.pending]: a card whose state cannot be
  /// read is offered again rather than silently marked as already handled.
  static AiProposalStatus _status(Object? raw) => switch (_string(raw)) {
        'confirmed' => AiProposalStatus.confirmed,
        'dismissed' => AiProposalStatus.dismissed,
        'failed' => AiProposalStatus.failed,
        _ => AiProposalStatus.pending,
      };

  static Set<String> _stringSet(Object? raw) {
    if (raw is! List) {
      return const <String>{};
    }
    return <String>{
      for (final item in raw)
        if (_string(item) case final String value) value,
    };
  }
}
