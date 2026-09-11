import '../../../../core/error/result.dart';

/// Contract for what the app learns from the user's own confirmations
/// (HU-06), over `MerchantCategoryLearning`.
///
/// The learning is private to the user: it is never shared, aggregated or
/// used to train anything. It syncs with their account like the rest of their
/// data so a new phone does not start from zero, and it holds no notification
/// content — only a normalized merchant key and a category id.
abstract class CaptureLearningRepository {
  /// Records that [merchantKey] is categorized as [categoryId]. Called only
  /// when the user confirms a capture, never by the parser. Re-confirming the
  /// same pairing raises its hit count; picking a different category rewrites
  /// the association (the user's latest decision is the right one).
  FutureResult<Unit> learnMerchantCategory({
    required String merchantKey,
    required String categoryId,
  });

  /// The learned category for [merchantKey], or `null` if none. A
  /// SUGGESTION: it is pre-filled and visible as such, never imposed
  /// silently, and it is only returned while the category is still usable
  /// (not trashed).
  FutureResult<String?> suggestedCategoryFor(String merchantKey);

  /// Forgets one association (HU-08).
  FutureResult<Unit> forgetMerchant(String merchantKey);

  /// Forgets everything learned (HU-08). Confirmed transactions keep the
  /// categories they already have — those are recorded facts, not
  /// suggestions.
  FutureResult<Unit> forgetAllLearning();
}
