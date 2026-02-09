import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

class AssetManager {
  static const String _modelFileName = 'gemma.task';

  // Logger with pretty printing
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  /// Checks if model is unpacked; if not, copies it to local storage.
  static Future<String> prepareModel() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localPath = "${directory.path}/$_modelFileName";
      final file = File(localPath);

      if (!await file.exists()) {
        _logger.i("📦 First launch detected. Unpacking AI model...");

        try {
          final data = await rootBundle.load("assets/models/$_modelFileName");
          final bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          await file.writeAsBytes(bytes, flush: true);

          _logger.i("✅ Model unpacked successfully at $localPath");
        } catch (e, stack) {
          _logger.e("❌ Failed to unpack model", error: e, stackTrace: stack);
          rethrow;
        }
      } else {
        _logger.d("🚀 Model already present. Skipping unpack.");
      }

      return localPath;
    } catch (e) {
      _logger.e("❌ Asset preparation failed: $e");
      rethrow;
    }
  }
}
