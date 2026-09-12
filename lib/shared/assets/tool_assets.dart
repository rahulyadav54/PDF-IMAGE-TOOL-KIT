import '../models/tool_catalog.dart';
import '../models/tool_type.dart';

/// Maps each tool to its custom illustration in assets/tools/.
abstract final class ToolAssets {
  static const _base = 'assets/tools';

  static String? pathFor(ToolType tool) => _map[tool];

  static String? pathForId(String id) {
    for (final entry in _map.entries) {
      if (entry.key.id == id) return entry.value;
    }
    return null;
  }

  static String? pathForRoute(String route) {
    final tool = ToolType.fromRoute(route);
    if (tool != null) return pathFor(tool);
    return null;
  }

  static String? pathForEntry(ToolCatalogEntry entry) {
    if (entry.tool != null) return pathFor(entry.tool!);
    return pathForRoute(entry.route);
  }

  static const settings = '$_base/settings.png';
  static const recentFiles = '$_base/recent_files.png';
  static const privacy = '$_base/privacy_security.png';
  static const upgradePro = '$_base/batch_processing.png';

  static const Map<ToolType, String> _map = {
    ToolType.scanToPdf: '$_base/scan_to_pdf.png',
    ToolType.compressPdf: '$_base/compress_pdf.png',
    ToolType.mergePdf: '$_base/merge_pdf.png',
    ToolType.splitPdf: '$_base/split_pdf.png',
    ToolType.imageToPdf: '$_base/image_to_pdf.png',
    ToolType.pdfToImage: '$_base/pdf_to_image.png',
    ToolType.imageConvert: '$_base/convert_format.png',
    ToolType.imageResize: '$_base/resize_image.png',
    ToolType.imageCompress: '$_base/compress_image.png',
    ToolType.imageStitch: '$_base/stitch_images.png',
    ToolType.idPhoto: '$_base/id_photo_maker.png',
    ToolType.batchProcessor: '$_base/batch_processing.png',
    ToolType.pdfPageEditor: '$_base/rotate_reorder.png',
    ToolType.editPdf: '$_base/edit_pdf.png',
    ToolType.protectPdf: '$_base/lock_pdf.png',
    ToolType.imageWatermark: '$_base/stitch_images.png',
    ToolType.imageFilters: '$_base/compress_image.png',
  };
}
