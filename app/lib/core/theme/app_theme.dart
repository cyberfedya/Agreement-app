import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';

/// Single accent + neutral surfaces. All component styling is centralized
/// here — widgets never hardcode colors, radii, or text styles.
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF4F5BD5); // calm indigo

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.25),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: Corners.mdRadius),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: Insets.x24, vertical: Insets.x16),
          shape: RoundedRectangleBorder(borderRadius: Corners.smRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: Insets.x24, vertical: Insets.x16),
          shape: RoundedRectangleBorder(borderRadius: Corners.smRadius),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x12),
          shape: RoundedRectangleBorder(borderRadius: Corners.smRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x16),
        border: OutlineInputBorder(borderRadius: Corners.smRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: Corners.smRadius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: Corners.smRadius,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: Insets.x12, vertical: Insets.x8),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: Corners.smRadius),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: Corners.lgRadius),
        backgroundColor: scheme.surfaceContainerLow,
      ),
      // Route transitions are handled centrally in AppRouter._fadeRoute.
    );
  }
}
