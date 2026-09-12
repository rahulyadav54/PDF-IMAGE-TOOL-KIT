/// Base exception for application-level errors with user-friendly messages.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class FilePickerCancelledException extends AppException {
  const FilePickerCancelledException()
      : super('File selection was cancelled.');
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException([String? permission])
      : super(
          permission != null
              ? '$permission permission is required for this action.'
              : 'Permission was denied. Please enable it in Settings.',
        );
}

class InvalidFileException extends AppException {
  const InvalidFileException([String? detail])
      : super(
          detail ??
              'The selected file is invalid or unsupported.',
        );
}

class ProcessingException extends AppException {
  const ProcessingException(super.message, {super.cause});
}

class StorageException extends AppException {
  const StorageException([String? detail])
      : super(
          detail ??
              'Unable to save the file. Check available storage and try again.',
        );
}
