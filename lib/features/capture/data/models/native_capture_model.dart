import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/entities/issuer_app.dart';
import '../../domain/entities/parsed_notification.dart';

/// Maps the platform-channel payloads of the native service into domain
/// entities. Lives in `data/` because the shape it reads is an implementation
/// detail of `PendingCaptureBuffer.kt`, not a domain concept.
///
/// The payload carries ONLY extracted fields. If a key holding notification
/// text ever appears here, the zero-retention rule (HU-03) has been broken on
/// the native side and this mapper is where it would show up.
abstract final class NativeCaptureModel {
  /// Returns the capture, or `null` when the entry is unusable (no positive
  /// amount, no rule id). A malformed entry is dropped silently: it came from
  /// a buffer that no longer has the text to re-derive it from.
  static ParsedNotification? fromMap(Map<Object?, Object?> map) {
    final String? packageName = map['packageName'] as String?;
    final String? issuerId = map['issuerId'] as String?;
    final String? ruleId = map['ruleId'] as String?;
    final int? amountMinor = _asInt(map['amountMinor']);
    if (packageName == null ||
        issuerId == null ||
        ruleId == null ||
        amountMinor == null ||
        amountMinor <= 0) {
      return null;
    }

    return ParsedNotification(
      issuerId: issuerId,
      sourcePackage: packageName,
      ruleId: ruleId,
      amountMinor: amountMinor,
      currency: (map['currency'] as String?) ?? 'COP',
      entryType: _entryType(map['entryType'] as String?),
      postedAt: DateTime.fromMillisecondsSinceEpoch(
        _asInt(map['postedAtEpochMs']) ?? 0,
      ),
      merchantRaw: _nullIfEmpty(map['merchantRaw'] as String?),
      accountHint: _nullIfEmpty(map['accountHint'] as String?),
      cardNetwork: _nullIfEmpty(map['cardNetwork'] as String?),
    );
  }

  static IssuerApp? issuerAppFromMap(Map<Object?, Object?> map) {
    final String? issuerId = map['issuerId'] as String?;
    final String? packageName = map['packageName'] as String?;
    if (issuerId == null || packageName == null) {
      return null;
    }
    return IssuerApp(
      issuerId: issuerId,
      displayName: (map['displayName'] as String?) ?? issuerId,
      packageName: packageName,
      installed: (map['installed'] as bool?) ?? false,
      enabled: (map['enabled'] as bool?) ?? false,
    );
  }

  static TransactionType _entryType(String? raw) => switch (raw) {
        'income' => TransactionType.income,
        'transfer' => TransactionType.transfer,
        _ => TransactionType.expense,
      };

  static int? _asInt(Object? value) => switch (value) {
        final int v => v,
        final String v => int.tryParse(v),
        _ => null,
      };

  static String? _nullIfEmpty(String? value) {
    final String trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
