/// Re-exports the pure decimal amount parser/formatter from `domain/utils/`
/// — it moved there so `presentation/` (the mapping-step preview sheets) can
/// use it without reaching into `data/` directly. Kept as a `data/` export
/// so the mappers and repository in this layer can keep importing it from
/// here.
library;

export '../../domain/utils/decimal_amount_parser.dart';
