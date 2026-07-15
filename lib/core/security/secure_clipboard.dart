import 'dart:async';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Copies sensitive data to the clipboard and clears it automatically after a
/// short delay, to shrink the exposure window (Cuentas HU-03: copying an
/// account number). Only clears if the clipboard **still** holds the copied
/// value, so we never wipe something the user copied afterwards.
@lazySingleton
class SecureClipboard {
  SecureClipboard();

  Timer? _clearTimer;

  Future<void> copySensitive(
    String value, {
    Duration clearAfter = const Duration(seconds: 60),
  }) async {
    await Clipboard.setData(ClipboardData(text: value));
    _clearTimer?.cancel();
    _clearTimer = Timer(clearAfter, () async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == value) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  void dispose() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }
}
