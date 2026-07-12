class AppConstants {
  const AppConstants._();

  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Document uploads OCR synchronously server-side before responding -
  /// several files (or a slow vision-model call) can easily exceed
  /// [defaultTimeout].
  static const Duration uploadTimeout = Duration(seconds: 90);
}
