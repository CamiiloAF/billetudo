/// Whether the mapping step (HU-05/HU-06) shows the autodetected mapping as
/// a short summary the user only has to confirm ("automatic"), or exposes
/// every raw column plus the three format fields (date/decimal/tipo-o-signo)
/// individually for hand-tuning ("manual"). Defaults to [automatic] because
/// most files match the app's own export vocabulary or a saved template
/// outright — HU-05 "un toque" — but a foreign export (Wallet, BudgetBakers…)
/// needs the escape hatch into [manual].
enum ImportMappingMode { automatic, manual }
