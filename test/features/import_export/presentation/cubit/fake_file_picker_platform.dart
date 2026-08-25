import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// A `FilePickerPlatform` that fakes the native "save" dialog, so
/// `SaveCopyCubit.saveToDevice` can be tested without a platform channel.
///
/// [savedPath] is what `FilePicker.saveFile` returns when the user "picks" a
/// destination — `null` fakes the user cancelling the native picker.
class FakeFilePickerPlatform extends FilePickerPlatform {
  FakeFilePickerPlatform({this.savedPath, this.throwOnSave = false});

  final String? savedPath;
  final bool throwOnSave;

  Uint8List? lastSavedBytes;
  String? lastSavedFileName;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    required String fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    required Uint8List bytes,
    void Function(FilePickerStatus)? onFileLoading,
    bool lockParentWindow = false,
  }) async {
    if (throwOnSave) {
      throw Exception('boom');
    }
    lastSavedBytes = bytes;
    lastSavedFileName = fileName;
    return savedPath;
  }
}
