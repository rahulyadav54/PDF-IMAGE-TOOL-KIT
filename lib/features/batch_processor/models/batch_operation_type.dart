import 'package:flutter/material.dart';

import '../../compress_pdf/models/compression_level.dart';
import '../../../shared/models/image_format.dart';

enum BatchOperationType {
  imageConvert(
    id: 'image_convert',
    label: 'Convert Images',
    description: 'Convert multiple images to the same format',
    icon: Icons.transform_outlined,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'],
    isImageOperation: true,
  ),
  imageCompress(
    id: 'image_compress',
    label: 'Compress Images',
    description: 'Reduce file size for multiple images',
    icon: Icons.photo_size_select_small_outlined,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
    isImageOperation: true,
  ),
  imageResize(
    id: 'image_resize',
    label: 'Resize Images',
    description: 'Scale multiple images by the same percentage',
    icon: Icons.aspect_ratio_outlined,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
    isImageOperation: true,
  ),
  compressPdf(
    id: 'compress_pdf',
    label: 'Compress PDFs',
    description: 'Compress multiple PDF files',
    icon: Icons.compress_outlined,
    allowedExtensions: ['pdf'],
    isImageOperation: false,
  );

  const BatchOperationType({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.allowedExtensions,
    required this.isImageOperation,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final List<String> allowedExtensions;
  final bool isImageOperation;
}

/// Shared configuration passed to batch file processors.
class BatchConfig {
  const BatchConfig({
    this.targetFormat = ImageFormat.jpg,
    this.quality = 75,
    this.resizePercentage = 50,
    this.compressionLevel = CompressionLevel.medium,
  });

  final ImageFormat targetFormat;
  final int quality;
  final int resizePercentage;
  final CompressionLevel compressionLevel;
}
