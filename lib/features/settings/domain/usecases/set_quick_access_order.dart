import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../home/domain/entities/quick_access_item.dart';
import '../repositories/app_settings_repository.dart';

/// Reorders Home's quick-access chips (`QuickAccessRow`), from the reorder
/// screen in Ajustes.
///
/// The business rule enforced here — not in `data/` — is that [order] must
/// be an exact permutation of [QuickAccessItem.values]: same 3 items, no
/// duplicates, none missing. A partial or malformed list is rejected before
/// it ever reaches the repository, so a corrupt write can never happen.
@injectable
class SetQuickAccessOrder {
  const SetQuickAccessOrder(this._repository);

  final AppSettingsRepository _repository;

  FutureResult<Unit> call(List<QuickAccessItem> order) {
    if (!QuickAccessItem.isValidOrder(order)) {
      return Future.value(
        const Left(
          ValidationFailure(
            'quickAccessOrder must be an exact permutation of '
            'QuickAccessItem.values',
            field: 'quickAccessOrder',
          ),
        ),
      );
    }
    return _repository.setQuickAccessOrder(order);
  }
}
