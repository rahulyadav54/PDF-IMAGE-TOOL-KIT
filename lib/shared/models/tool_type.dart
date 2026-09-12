import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum ToolCategory { pdf, image, other, batch }

enum ToolCardCategory { pdf, image, other, batch }

enum ToolType {
  scanToPdf(
    id: 'scan_to_pdf',
    title: 'Scan to PDF',
    subtitle: 'Scan documents with your camera',
    icon: Icons.document_scanner_rounded,
    accentColor: AppColors.electricBlue,
    cardCategory: ToolCardCategory.pdf,
    category: ToolCategory.pdf,
    route: '/scan-to-pdf',
  ),
  compressPdf(
    id: 'compress_pdf',
    title: 'Compress PDF',
    subtitle: 'Reduce PDF file size',
    icon: Icons.compress_rounded,
    accentColor: AppColors.red,
    cardCategory: ToolCardCategory.pdf,
    category: ToolCategory.pdf,
    route: '/compress-pdf',
  ),
  mergePdf(
    id: 'merge_pdf',
    title: 'Merge PDF',
    subtitle: 'Combine multiple PDFs',
    icon: Icons.merge_type_rounded,
    accentColor: AppColors.purple,
    cardCategory: ToolCardCategory.pdf,
    category: ToolCategory.pdf,
    route: '/merge-pdf',
  ),
  splitPdf(
    id: 'split_pdf',
    title: 'Split PDF',
    subtitle: 'Extract or split pages',
    icon: Icons.content_cut_rounded,
    accentColor: AppColors.orange,
    cardCategory: ToolCardCategory.pdf,
    category: ToolCategory.pdf,
    route: '/split-pdf',
  ),
  imageToPdf(
    id: 'image_to_pdf',
    title: 'Image to PDF',
    subtitle: 'Convert images to a PDF',
    icon: Icons.picture_as_pdf_rounded,
    accentColor: AppColors.green,
    cardCategory: ToolCardCategory.pdf,
    category: ToolCategory.pdf,
    route: '/image-to-pdf',
  ),
  pdfToImage(
    id: 'pdf_to_image',
    title: 'PDF to Image',
    subtitle: 'Export pages as JPG or PNG',
    icon: Icons.image_rounded,
    accentColor: AppColors.cyan,
    cardCategory: ToolCardCategory.pdf,
    category: ToolCategory.pdf,
    route: '/pdf-to-image',
  ),
  imageConvert(
    id: 'image_convert',
    title: 'Convert Format',
    subtitle: 'Change image format',
    icon: Icons.transform_rounded,
    accentColor: AppColors.violet,
    cardCategory: ToolCardCategory.image,
    category: ToolCategory.image,
    route: '/image-convert',
  ),
  imageCompress(
    id: 'image_compress',
    title: 'Compress Image',
    subtitle: 'Reduce image file size',
    icon: Icons.photo_size_select_small_rounded,
    accentColor: AppColors.orange,
    cardCategory: ToolCardCategory.image,
    category: ToolCategory.image,
    route: '/image-compress',
  ),
  imageResize(
    id: 'image_resize',
    title: 'Resize Image',
    subtitle: 'Change dimensions or target size',
    icon: Icons.aspect_ratio_rounded,
    accentColor: AppColors.green,
    cardCategory: ToolCardCategory.image,
    category: ToolCategory.image,
    route: '/image-resize',
  ),
  imageStitch(
    id: 'image_stitch',
    title: 'Stitch Images',
    subtitle: 'Combine photos into one image',
    icon: Icons.view_agenda_rounded,
    accentColor: AppColors.pink,
    cardCategory: ToolCardCategory.image,
    category: ToolCategory.image,
    route: '/image-stitch',
  ),
  idPhoto(
    id: 'id_photo',
    title: 'ID Photo Maker',
    subtitle: 'Passport, PAN, visa photo sizes',
    icon: Icons.badge_rounded,
    accentColor: AppColors.purple,
    cardCategory: ToolCardCategory.other,
    category: ToolCategory.other,
    route: '/id-photo',
  ),
  batchProcessor(
    id: 'batch_processor',
    title: 'Batch Processing',
    subtitle: 'Process multiple files at once',
    icon: Icons.layers_rounded,
    accentColor: AppColors.electricBlue,
    cardCategory: ToolCardCategory.other,
    category: ToolCategory.batch,
    route: '/batch-processor',
  ),
  protectPdf(
    id: 'protect_pdf',
    title: 'Lock PDF',
    subtitle: 'Password-protect your PDF',
    icon: Icons.lock_rounded,
    accentColor: AppColors.red,
    cardCategory: ToolCardCategory.other,
    category: ToolCategory.other,
    route: '/protect-pdf',
  ),
  pdfPageEditor(
    id: 'pdf_page_editor',
    title: 'Rotate & Reorder',
    subtitle: 'Fix page order and orientation',
    icon: Icons.rotate_right_rounded,
    accentColor: AppColors.teal,
    cardCategory: ToolCardCategory.other,
    category: ToolCategory.other,
    route: '/pdf-page-editor',
  ),
  editPdf(
    id: 'edit_pdf',
    title: 'Edit PDF',
    subtitle: 'Edit text, images, pages & annotations',
    icon: Icons.edit_note_rounded,
    accentColor: AppColors.electricBlue,
    cardCategory: ToolCardCategory.pdf,
    category: ToolCategory.pdf,
    route: '/edit-pdf',
  ),
  imageWatermark(
    id: 'image_watermark',
    title: 'Image Watermark',
    subtitle: 'Add text or logo watermark',
    icon: Icons.water_drop_rounded,
    accentColor: AppColors.cyan,
    cardCategory: ToolCardCategory.image,
    category: ToolCategory.image,
    route: '/image-watermark',
  ),
  imageFilters(
    id: 'image_filters',
    title: 'Image Filters',
    subtitle: 'Adjust brightness, contrast & presets',
    icon: Icons.tune_rounded,
    accentColor: AppColors.violet,
    cardCategory: ToolCardCategory.image,
    category: ToolCategory.image,
    route: '/image-filters',
  );

  const ToolType({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.cardCategory,
    required this.category,
    required this.route,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final ToolCardCategory cardCategory;
  final ToolCategory category;
  final String route;

  static ToolType? fromRoute(String route) {
    for (final tool in values) {
      if (tool.route == route) return tool;
    }
    return null;
  }

  static List<ToolType> get pdfTools =>
      values.where((t) => t.category == ToolCategory.pdf).toList();

  static List<ToolType> get imageTools =>
      values.where((t) => t.category == ToolCategory.image).toList();

  static List<ToolType> get otherTools =>
      values.where((t) => t.category == ToolCategory.other).toList();
}
