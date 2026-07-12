import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app/core/theme/app_tokens.dart';

/// Notary-grade blue + white. No purple drift, no tonal noise — every
/// surface is either white/navy or a step of the single blue accent.
class AppTheme {
  const AppTheme._();

  static const Color _blue = Color(0xFF1652D6);

  static final ColorScheme _light = ColorScheme(
    brightness: Brightness.light,
    primary: _blue,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFE6ECFB),
    onPrimaryContainer: const Color(0xFF0B3488),
    secondary: _blue,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFE6ECFB),
    onSecondaryContainer: const Color(0xFF0B3488),
    tertiary: _blue,
    onTertiary: Colors.white,
    error: const Color(0xFFBA1A1A),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: const Color(0xFF10151F),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF6F8FC),
    surfaceContainer: const Color(0xFFF0F3FA),
    surfaceContainerHigh: const Color(0xFFE9EDF7),
    surfaceContainerHighest: const Color(0xFFE1E7F4),
    onSurfaceVariant: const Color(0xFF4B5568),
    outline: const Color(0xFFB7C0D6),
    outlineVariant: const Color(0xFFDCE2F0),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: const Color(0xFF10151F),
    onInverseSurface: Colors.white,
    inversePrimary: const Color(0xFFAEC2FF),
  );

  static final ColorScheme _dark = ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFF7C9CFF),
    onPrimary: const Color(0xFF072164),
    primaryContainer: const Color(0xFF15398F),
    onPrimaryContainer: const Color(0xFFDCE4FF),
    secondary: const Color(0xFF7C9CFF),
    onSecondary: const Color(0xFF072164),
    secondaryContainer: const Color(0xFF15398F),
    onSecondaryContainer: const Color(0xFFDCE4FF),
    tertiary: const Color(0xFF7C9CFF),
    onTertiary: const Color(0xFF072164),
    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
    surface: const Color(0xFF0B1220),
    onSurface: const Color(0xFFE3E8F4),
    surfaceContainerLowest: const Color(0xFF060A13),
    surfaceContainerLow: const Color(0xFF101928),
    surfaceContainer: const Color(0xFF141E30),
    surfaceContainerHigh: const Color(0xFF1B2740),
    surfaceContainerHighest: const Color(0xFF23304C),
    onSurfaceVariant: const Color(0xFFA9B3C9),
    outline: const Color(0xFF4A5670),
    outlineVariant: const Color(0xFF2A3550),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: const Color(0xFFE3E8F4),
    onInverseSurface: const Color(0xFF10151F),
    inversePrimary: _blue,
  );

  static ThemeData get light => _build(_light);
  static ThemeData get dark => _build(_dark);

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    // Inter: neutral, highly legible, full Cyrillic - the single family
    // for the whole app, so nothing ever falls back to the stock Material
    // look. Weight/tracking tweaks are applied on top of it.
    final interTheme = GoogleFonts.interTextTheme(base.textTheme);
    final textTheme = interTheme.copyWith(
      displaySmall: interTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: interTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineSmall: interTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.25),
      titleLarge: interTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: interTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: interTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: interTheme.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: interTheme.bodyMedium?.copyWith(height: 1.5),
      labelLarge: interTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
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
