import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';

/// Every surface the account gate can intercept
/// (`docs/requirements/fase-1/15-gate-cuenta.md` HU-03), each with its own icon and
/// copy in `billetudo.pen` (`design-system/billetudo/pages/gate-cuenta.md`).
enum AccountGateSurface {
  /// Registrar movimiento (ingreso/gasto), incluido el FAB de Home y el CTA
  /// de Movimientos. `Zjsfz`.
  movement,

  /// Transferencia: exige **dos** cuentas activas, no una — the only surface
  /// whose copy depends on the current count (`XYfSq`/`goGwA`).
  transfer,

  /// Crear pago programado. `G0mfgY`.
  scheduledPayment,

  /// Deuda con desembolso/abono que mueve dinero (rama "con caja"). `K6bGhq`.
  debtCash,

  /// Aporte/retiro de meta con "¿Mover dinero de una cuenta?" en Sí. `xU4uz`.
  goalMovement,

  /// Enlazar un movimiento existente a una deuda o meta. `oHAVJ`.
  linkMovement,

  /// Crear presupuesto — bloquea **toda** la creación, incluido el alcance
  /// "Todo" (decisión de producto revertida 2026-08-06, ver
  /// `docs/requirements/fase-1/15-gate-cuenta.md` HU-03). `flt4U`.
  budget,

  /// Campo "Cuenta vinculada" de Metas: ayuda informativa no bloqueante — el
  /// usuario puede crear la meta sin cuenta, este surface solo interviene
  /// cuando toca específicamente ese campo sin tener cuentas. `kOr4c`.
  goalLinkedAccount,
}

/// The icon, title and message the bridge sheet shows for a given
/// [AccountGateSurface] — and, for [AccountGateSurface.transfer], the current
/// account count, since `XYfSq` (0 cuentas) and `goGwA` (1 cuenta) are
/// different copy for the same surface.
class AccountGateCopy {
  const AccountGateCopy({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  /// How many active accounts [surface] needs before the gate lets the
  /// action through. Every surface but [AccountGateSurface.transfer] just
  /// needs one; transfer needs two (HU-02).
  static int requiredCount(AccountGateSurface surface) =>
      surface == AccountGateSurface.transfer ? 2 : 1;

  static AccountGateCopy resolve(
    AppLocalizations l10n,
    AccountGateSurface surface, {
    required int currentCount,
  }) {
    switch (surface) {
      case AccountGateSurface.movement:
        return AccountGateCopy(
          icon: LucideIcons.landmark,
          title: l10n.accountGateMovementTitle,
          message: l10n.accountGateMovementMessage,
        );
      case AccountGateSurface.transfer:
        return currentCount >= 1
            ? AccountGateCopy(
                icon: LucideIcons.arrowLeftRight,
                title: l10n.accountGateTransferOneTitle,
                message: l10n.accountGateTransferOneMessage,
              )
            : AccountGateCopy(
                icon: LucideIcons.arrowLeftRight,
                title: l10n.accountGateTransferZeroTitle,
                message: l10n.accountGateTransferZeroMessage,
              );
      case AccountGateSurface.scheduledPayment:
        return AccountGateCopy(
          icon: LucideIcons.calendarClock,
          title: l10n.accountGateScheduledPaymentTitle,
          message: l10n.accountGateScheduledPaymentMessage,
        );
      case AccountGateSurface.debtCash:
        return AccountGateCopy(
          icon: LucideIcons.creditCard,
          title: l10n.accountGateDebtCashTitle,
          message: l10n.accountGateDebtCashMessage,
        );
      case AccountGateSurface.goalMovement:
        return AccountGateCopy(
          icon: LucideIcons.piggyBank,
          title: l10n.accountGateGoalMovementTitle,
          message: l10n.accountGateGoalMovementMessage,
        );
      case AccountGateSurface.linkMovement:
        return AccountGateCopy(
          icon: LucideIcons.link,
          title: l10n.accountGateLinkMovementTitle,
          message: l10n.accountGateLinkMovementMessage,
        );
      case AccountGateSurface.budget:
        return AccountGateCopy(
          icon: LucideIcons.wallet,
          title: l10n.accountGateBudgetTitle,
          message: l10n.accountGateBudgetMessage,
        );
      case AccountGateSurface.goalLinkedAccount:
        return AccountGateCopy(
          icon: LucideIcons.landmark,
          title: l10n.accountGateGoalLinkedAccountTitle,
          message: l10n.accountGateGoalLinkedAccountMessage,
        );
    }
  }
}
