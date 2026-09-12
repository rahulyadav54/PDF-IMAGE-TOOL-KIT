import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';

final pdfFormFillerServiceProvider =
    Provider<PdfFormFillerService>((ref) => PdfFormFillerService(ref));

class PdfFormFieldInfo {
  const PdfFormFieldInfo({
    required this.index,
    required this.name,
    required this.type,
    this.value,
    this.options = const [],
    this.isReadOnly = false,
  });

  final int index;
  final String name;
  final String type;
  final String? value;
  final List<String> options;
  final bool isReadOnly;
}

class PdfFormFillResult {
  const PdfFormFillResult({
    required this.outputPath,
    required this.fileName,
    required this.outputSizeBytes,
  });

  final String outputPath;
  final String fileName;
  final int outputSizeBytes;
}

class PdfFormFillerService {
  PdfFormFillerService(this._ref);

  final Ref _ref;

  Future<List<PdfFormFieldInfo>> loadFields(String inputPath) async {
    final bytes = await File(inputPath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      if (document.form.fields.count == 0) return const [];

      final fields = <PdfFormFieldInfo>[];
      for (var i = 0; i < document.form.fields.count; i++) {
        final field = document.form.fields[i];
        fields.add(
          PdfFormFieldInfo(
            index: i,
            name: field.name ?? 'field_$i',
            type: field.runtimeType.toString(),
            value: _readFieldValue(field),
            options: _readOptions(field),
            isReadOnly: field.readOnly,
          ),
        );
      }
      return fields;
    } finally {
      document.dispose();
    }
  }

  Future<PdfFormFillResult> saveFilledForm({
    required String inputPath,
    required Map<int, String> values,
    bool flatten = false,
  }) async {
    final bytes = await File(inputPath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    try {
      if (document.form.fields.count == 0) {
        throw const ProcessingException('This PDF does not contain form fields.');
      }

      for (final entry in values.entries) {
        if (entry.key < 0 || entry.key >= document.form.fields.count) continue;
        final field = document.form.fields[entry.key];
        _writeFieldValue(field, entry.value);
      }

      if (flatten) {
        document.form.flattenAllFields();
      }

      final outputBytes = Uint8List.fromList(await document.save());
      final fileName =
          FilenameGenerator.withSuffix(inputPath, 'filled', newExtension: '.pdf');
      final outputPath =
          await _ref.read(fileServiceProvider).saveToOutput(fileName, outputBytes);

      return PdfFormFillResult(
        outputPath: outputPath,
        fileName: fileName,
        outputSizeBytes: outputBytes.length,
      );
    } finally {
      document.dispose();
    }
  }

  String? _readFieldValue(PdfField field) {
    if (field is PdfTextBoxField) return field.text;
    if (field is PdfCheckBoxField) return field.isChecked ? 'true' : 'false';
    if (field is PdfRadioButtonListField) {
      return field.selectedIndex >= 0 ? field.selectedIndex.toString() : null;
    }
    if (field is PdfComboBoxField) return field.selectedValue;
    if (field is PdfListBoxField) {
      return field.selectedValues?.join(', ');
    }
    return null;
  }

  List<String> _readOptions(PdfField field) {
    if (field is PdfComboBoxField) {
      final items = <String>[];
      for (var i = 0; i < field.items.count; i++) {
        items.add(field.items[i].text);
      }
      return items;
    }
    if (field is PdfListBoxField) {
      final items = <String>[];
      for (var i = 0; i < field.items.count; i++) {
        items.add(field.items[i].text);
      }
      return items;
    }
    if (field is PdfRadioButtonListField) {
      return List.generate(field.items.count, (i) => 'Option ${i + 1}');
    }
    return const [];
  }

  void _writeFieldValue(PdfField field, String value) {
    if (field is PdfTextBoxField) {
      field.text = value;
      return;
    }
    if (field is PdfCheckBoxField) {
      field.isChecked = value.toLowerCase() == 'true' || value == '1';
      return;
    }
    if (field is PdfRadioButtonListField) {
      final index = int.tryParse(value);
      if (index != null && index >= 0 && index < field.items.count) {
        field.selectedIndex = index;
      }
      return;
    }
    if (field is PdfComboBoxField) {
      field.selectedValue = value;
      return;
    }
    if (field is PdfListBoxField) {
      field.selectedValues = [value];
    }
  }
}
