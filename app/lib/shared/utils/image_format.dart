/// Sniffs an image's real format from its magic bytes - mirrors the
/// backend's own `DocumentUploadValidator.DetectContentType` exactly, byte
/// for byte, so whatever content type Flutter declares is guaranteed to
/// match what the backend independently detects.
///
/// This exists because `XFile.mimeType` (from `image_picker`) is
/// frequently null on Android - falling back to a hardcoded
/// `'image/jpeg'` guess meant a PNG screenshot or a WebP gallery pick
/// would silently mismatch the backend's own detection and bounce back
/// as `DOCUMENT_CONTENT_TYPE_MISMATCH`, which read to the user as a
/// generic "server error" for a photo that was never actually broken.
library;

/// `image/jpeg`, `image/png`, or `image/webp` - null when the bytes don't
/// start with a signature the backend (and this app) recognizes as a
/// supported image format.
String? sniffImageContentType(List<int> bytes) {
  if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 && // "RIFF"
      bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50 // "WEBP"
      ) {
    return 'image/webp';
  }
  return null;
}

/// The one extension the backend accepts for [contentType] - used to
/// rename a file whose original name/extension doesn't match what its
/// bytes actually are (e.g. a camera plugin that names everything
/// `image.tmp`), since the backend rejects that combination too.
String extensionForContentType(String contentType) => switch (contentType) {
  'image/jpeg' => '.jpg',
  'image/png' => '.png',
  'image/webp' => '.webp',
  _ => '',
};

/// Renames [fileName] to end with the extension that actually matches
/// [contentType], preserving the base name. Guarantees the (contentType,
/// fileName) pair the backend validates never disagrees with itself.
String normalizedFileName(String fileName, String contentType) {
  final dot = fileName.lastIndexOf('.');
  final base = dot > 0 ? fileName.substring(0, dot) : fileName;
  return '$base${extensionForContentType(contentType)}';
}
