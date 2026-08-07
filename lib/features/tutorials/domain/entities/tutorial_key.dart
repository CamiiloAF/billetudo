/// The 12 stable contextual-help minitutorials (`docs/requirements/16-minitutoriales.md`).
///
/// [id] is the value persisted as `TutorialViews.id` — a small fixed string,
/// NOT a random UUID, so it stays stable across app versions and is shared
/// (repeated) across every user who has seen that tutorial. Never rename an
/// existing [id]: a tutorial whose key no longer exists in this enum is
/// simply ignored, per the doc's "no migration, no cleanup" edge case; the
/// same applies in reverse — do not reuse a retired key for a new tutorial.
enum TutorialKey {
  /// HU-01 — Presupuestos main screen, first access.
  budgetsScreen('tutorial-budgets'),

  /// HU-01 — Metas main screen, first access.
  goalsScreen('tutorial-goals'),

  /// HU-01 — Deudas main screen, first access.
  debtsScreen('tutorial-debts'),

  /// HU-01 — Pagos programados main screen, first access.
  scheduledPaymentsScreen('tutorial-scheduled-payments'),

  /// HU-02 — Linking an existing transaction to a debt (attribute, not
  /// duplicate).
  debtLinkMovement('tutorial-debt-link-movement'),

  /// HU-02 — Linking an existing transaction to a goal. Same copy pattern as
  /// [debtLinkMovement] by design.
  goalLinkMovement('tutorial-goal-link-movement'),

  /// HU-02 — The "add to an account?" toggle on a debt payment
  /// (`08-deudas.md` HU-02): "No" still lowers the debt without touching a
  /// balance.
  debtPaymentToggle('tutorial-debt-payment-toggle'),

  /// HU-02 — The "move money from an account?" toggle on a goal
  /// contribution (`07-metas.md` HU-03): earmarking vs. an actual transfer.
  goalContributionToggle('tutorial-goal-contribution-toggle'),

  /// HU-02 — Creating a debt's scheduled installment (`08-deudas.md`
  /// HU-03): configured from the debt, confirmed from the scheduled-payments
  /// tray, and its generated transaction touches both the account and the
  /// debt.
  debtScheduledInstallment('tutorial-debt-scheduled-installment'),

  /// HU-02 — The `countsInBudget` toggle on a transfer.
  budgetableTransfer('tutorial-budgetable-transfer'),

  /// HU-02 — Turning on "Modo sobres" (zero-based) from its settings
  /// toggle. Skipped when the Presupuestos screen tutorial ([budgetsScreen])
  /// has already been seen (no-chaining rule already covers the concept).
  envelopeMode('tutorial-envelope-mode'),

  /// HU-02 — Creating a user's *second* active budget
  /// (`design-system/billetudo/pages/presupuestos.md`, "Discoverability"):
  /// the moment the "¿cuál se destaca en Inicio?" ambiguity first appears —
  /// the first budget was already auto-featured with no user action needed,
  /// so nothing to explain existed before this point.
  budgetFeaturedChoice('tutorial-budget-featured-choice');

  const TutorialKey(this.id);

  /// Stable key persisted as `TutorialViews.id`. See class doc.
  final String id;

  /// The 4 HU-01 screen-level tutorials — the ones with a navigation CTA and
  /// a `?` reopen affordance in their screen's header.
  static const Set<TutorialKey> screenTutorials = {
    budgetsScreen,
    goalsScreen,
    debtsScreen,
    scheduledPaymentsScreen,
  };

  /// The 8 HU-02 sub-flow tutorials — short, no navigation CTA.
  static const Set<TutorialKey> subFlowTutorials = {
    debtLinkMovement,
    goalLinkMovement,
    debtPaymentToggle,
    goalContributionToggle,
    debtScheduledInstallment,
    budgetableTransfer,
    envelopeMode,
    budgetFeaturedChoice,
  };

  /// Whether this is one of the 4 HU-01 screen tutorials (vs. a HU-02
  /// sub-flow one).
  bool get isScreenTutorial => screenTutorials.contains(this);
}
