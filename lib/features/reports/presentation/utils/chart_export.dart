import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Export as image (HU-05, criterion 15): `RepaintBoundary → toImage → PNG`,
/// then the system share sheet. The [RepaintBoundary] the caller wraps must
/// cover **only the active chart's card** (title + range), never the tabs,
/// header or export icon — the caller decides that scope by where it puts
/// the boundary, this class only does the capture/share mechanics.
@lazySingleton
class ChartExport {
  const ChartExport();

  /// Captures [boundaryKey]'s render object as a PNG at [pixelRatio] and
  /// hands it to the native share sheet with [shareText]. Returns `false`
  /// (without throwing) when the boundary is not yet laid out — the caller
  /// shows `reportsExportError` to the user in that case.
  Future<bool> exportAndShare({
    required GlobalKey boundaryKey,
    required String fileName,
    required String shareText,
    double pixelRatio = 3,
  }) async {
    final renderObject = boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      return false;
    }
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return false;
    }
    final bytes = byteData.buffer.asUint8List();
    final path = await _writeTempFile(fileName, bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: shareText),
    );
    return true;
  }

  Future<String> _writeTempFile(String fileName, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
