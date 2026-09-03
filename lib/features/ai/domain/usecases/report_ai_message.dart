import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/ai_report.dart';
import '../repositories/ai_report_repository.dart';

/// Reports one generated message for review.
@injectable
class ReportAiMessage {
  const ReportAiMessage(this._repository);

  final AiReportRepository _repository;

  FutureResult<Unit> call(AiReport report) => _repository.report(report);
}
