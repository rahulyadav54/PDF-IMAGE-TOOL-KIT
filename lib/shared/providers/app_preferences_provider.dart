import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../features/compress_pdf/models/compression_level.dart';
import '../../features/image_to_pdf/models/image_pdf_processing_options.dart';
import '../../features/pdf_to_image/models/image_export_format.dart';
import '../models/app_preferences.dart';

final appPreferencesProvider =
    StateNotifierProvider<AppPreferencesNotifier, AppPreferences>(
  (ref) => AppPreferencesNotifier(),
);

class AppPreferencesNotifier extends StateNotifier<AppPreferences> {
  AppPreferencesNotifier() : super(const AppPreferences()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final pdfQualityName = prefs.getString(AppConstants.pdfQualityKey);
    final compressionName = prefs.getString(AppConstants.compressionLevelKey);
    final exportName = prefs.getString(AppConstants.exportFormatKey);
    final imageQuality = prefs.getInt(AppConstants.imageCompressQualityKey);

    state = AppPreferences(
      pdfQuality: _parseEnum(
        pdfQualityName,
        ImagePdfQuality.values,
        ImagePdfQuality.high,
      ),
      compressionLevel: _parseEnum(
        compressionName,
        CompressionLevel.values,
        CompressionLevel.medium,
      ),
      exportFormat: _parseEnum(
        exportName,
        ImageExportFormat.values,
        ImageExportFormat.jpg,
      ),
      imageCompressQuality: imageQuality ?? 75,
    );
  }

  T _parseEnum<T extends Enum>(String? name, List<T> values, T fallback) {
    if (name == null) return fallback;
    return values.firstWhere((e) => e.name == name, orElse: () => fallback);
  }

  Future<void> setPdfQuality(ImagePdfQuality quality) async {
    state = state.copyWith(pdfQuality: quality);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.pdfQualityKey, quality.name);
  }

  Future<void> setCompressionLevel(CompressionLevel level) async {
    state = state.copyWith(compressionLevel: level);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.compressionLevelKey, level.name);
  }

  Future<void> setExportFormat(ImageExportFormat format) async {
    state = state.copyWith(exportFormat: format);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.exportFormatKey, format.name);
  }

  Future<void> setImageCompressQuality(int quality) async {
    state = state.copyWith(imageCompressQuality: quality.clamp(20, 100));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.imageCompressQualityKey, state.imageCompressQuality);
  }
}
