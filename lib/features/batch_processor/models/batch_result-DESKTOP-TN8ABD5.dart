class BatchFileResult {
  const BatchFileResult({
    required this.inputPath,
    required this.fileName,
    required this.success,
    this.outputPath,
    this.outputSizeBytes,
    this.errorMessage,
  });

  final String inputPath;
  final String fileName;
  final bool success;
  final String? outputPath;
  final int? outputSizeBytes;
  final String? errorMessage;

  factory BatchFileResult.successResult({
    required String inputPath,
    required String fileName,
    required String outputPath,
    required int outputSizeBytes,
  }) {
    return BatchFileResult(
      inputPath: inputPath,
      fileName: fileName,
      success: true,
      outputPath: outputPath,
      outputSizeBytes: outputSizeBytes,
    );
  }

  factory BatchFileResult.failure({
    required String inputPath,
    required String fileName,
    required String errorMessage,
  }) {
    return BatchFileResult(
      inputPath: inputPath,
      fileName: fileName,
      success: false,
      errorMessage: errorMessage,
    );
  }
}

class BatchProgress {
  const BatchProgress({
    required this.current,
    required this.total,
    required this.currentFileName,
  });

  final int current;
  final int total;
  final String currentFileName;

  double get fraction => total > 0 ? current / total : 0;
}

class BatchRunResult {
  const BatchRunResult({
    required this.operationLabel,
    required this.fileResults,
    required this.primaryOutputPath,
    required this.primaryFileName,
    required this.totalOutputBytes,
    this.zipPath,
  });

  final String operationLabel;
  final List<BatchFileResult> fileResults;
  final String primaryOutputPath;
  final String primaryFileName;
  final int totalOutputBytes;
  final String? zipPath;

  int get successCount => fileResults.where((r) => r.success).length;
  int get failureCount => fileResults.where((r) => !r.success).length;
  bool get hasZip => zipPath != null;
  List<BatchFileResult> get failures =>
      fileResults.where((r) => !r.success).toList();
}
