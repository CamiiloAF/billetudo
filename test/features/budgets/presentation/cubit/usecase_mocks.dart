import 'package:billetudo/features/budgets/domain/usecases/get_zero_based_summary.dart';
import 'package:mocktail/mocktail.dart';

/// The cubit only ever talks to a use case, so this is the only seam the
/// presentation test needs. Mocking the repository here instead would test a
/// dependency the cubit is not allowed to have.
class MockGetZeroBasedSummary extends Mock implements GetZeroBasedSummary {}
