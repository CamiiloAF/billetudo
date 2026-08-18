/// The Nivel 0/1/2 tier a chart view belongs to (see
/// `docs/requirements/fase-1/10-graficas-informes.md`, "Costura para Nivel 1/2").
///
/// `essential` is Nivel 0: gratis, ilimitado, nunca detrás de anuncio o pago.
/// `advanced` is Nivel 1 (Modo anuncios) / Nivel 2 (Premium): does not exist
/// yet in Fase 0 — no `ChartView` in `ChartCatalog` uses it today, and no UI
/// is built for it. It exists purely as costura so Fase 4 can add advanced
/// views without retrofitting this catalog.
enum ChartTier { essential, advanced }
