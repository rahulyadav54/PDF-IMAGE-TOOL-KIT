import 'dart:convert';

/// Metadata for a recently processed file (path reference only, no duplication).
class RecentFile {
  const RecentFile({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.operation,
    required this.processedAt,
    required this.fileSizeBytes,
  });

  final String id;
  final String fileName;
  final String filePath;
  final String fileType;
  final String operation;
  final DateTime processedAt;
  final int fileSizeBytes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'fileType': fileType,
        'operation': operation,
        'processedAt': processedAt.toIso8601String(),
        'fileSizeBytes': fileSizeBytes,
      };

  factory RecentFile.fromJson(Map<String, dynamic> json) => RecentFile(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        filePath: json['filePath'] as String,
        fileType: json['fileType'] as String,
        operation: json['operation'] as String,
        processedAt: DateTime.parse(json['processedAt'] as String),
        fileSizeBytes: json['fileSizeBytes'] as int,
      );

  static String encodeList(List<RecentFile> files) =>
      jsonEncode(files.map((f) => f.toJson()).toList());

  static List<RecentFile> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => RecentFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  RecentFile copyWith({
    String? fileName,
    String? filePath,
    String? fileType,
    String? operation,
    DateTime? processedAt,
    int? fileSizeBytes,
  }) {
    return RecentFile(
      id: id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      operation: operation ?? this.operation,
      processedAt: processedAt ?? this.processedAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }
}
