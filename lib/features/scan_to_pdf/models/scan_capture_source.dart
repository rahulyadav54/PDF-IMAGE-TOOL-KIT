/// Where a scanned page image came from — controls crop vs enhance behavior.
enum ScanCaptureSource {
  /// CunningDocumentScanner — user already cropped in the native UI.
  nativeScanner,
  /// Photo picker — may include desk/background, needs smart crop.
  gallery,
  /// File picker — may include desk/background, needs smart crop.
  files,
}
