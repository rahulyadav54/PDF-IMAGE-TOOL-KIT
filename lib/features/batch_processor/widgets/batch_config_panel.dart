import 'package:flutter/material.dart';

import '../../../shared/models/image_format.dart';
import '../../compress_pdf/models/compression_level.dart';
import '../../compress_pdf/widgets/compression_level_selector.dart';
import '../../image_compress/widgets/quality_slider_card.dart';
import '../../image_convert/widgets/image_format_selector.dart';
import '../models/batch_operation_type.dart';

class BatchConfigPanel extends StatelessWidget {
  const BatchConfigPanel({
    super.key,
    required this.operationType,
    required this.config,
    required this.onChanged,
    this.enabled = true,
  });

  final BatchOperationType operationType;
  final BatchConfig config;
  final ValueChanged<BatchConfig> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    switch (operationType) {
      case BatchOperationType.imageConvert:
        return ImageFormatSelector(
          selected: config.targetFormat,
          onChanged: enabled
              ? (format) => onChanged(config.copyWith(targetFormat: format))
              : (_) {},
        );
      case BatchOperationType.imageCompress:
        return QualitySliderCard(
          quality: config.quality,
          onChanged: enabled
              ? (quality) => onChanged(config.copyWith(quality: quality))
              : (_) {},
        );
      case BatchOperationType.imageResize:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scale',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${config.resizePercentage}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                Slider(
                  value: config.resizePercentage.toDouble(),
                  min: 10,
                  max: 200,
                  divisions: 19,
                  label: '${config.resizePercentage}%',
                  onChanged: enabled
                      ? (value) => onChanged(
                            config.copyWith(resizePercentage: value.round()),
                          )
                      : null,
                ),
                Text(
                  'All images will be scaled by the same percentage.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        );
      case BatchOperationType.compressPdf:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compression Level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            CompressionLevelSelector(
              selected: config.compressionLevel,
              onChanged: enabled
                  ? (level) => onChanged(config.copyWith(compressionLevel: level))
                  : (_) {},
            ),
          ],
        );
    }
  }
}

extension on BatchConfig {
  BatchConfig copyWith({
    ImageFormat? targetFormat,
    int? quality,
    int? resizePercentage,
    CompressionLevel? compressionLevel,
  }) {
    return BatchConfig(
      targetFormat: targetFormat ?? this.targetFormat,
      quality: quality ?? this.quality,
      resizePercentage: resizePercentage ?? this.resizePercentage,
      compressionLevel: compressionLevel ?? this.compressionLevel,
    );
  }
}
