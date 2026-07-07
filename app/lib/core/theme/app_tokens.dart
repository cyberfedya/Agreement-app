import 'package:flutter/widgets.dart';

/// Spacing scale. Every padding/gap in the app comes from here.
abstract final class Insets {
  static const double x4 = 4;
  static const double x8 = 8;
  static const double x12 = 12;
  static const double x16 = 16;
  static const double x20 = 20;
  static const double x24 = 24;
  static const double x32 = 32;
  static const double x40 = 40;
  static const double x48 = 48;
  static const double x64 = 64;

  /// Default horizontal page padding.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: x20);
}

/// Corner radius scale.
abstract final class Corners {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;

  static final BorderRadius smRadius = BorderRadius.circular(sm);
  static final BorderRadius mdRadius = BorderRadius.circular(md);
  static final BorderRadius lgRadius = BorderRadius.circular(lg);
  static final BorderRadius xlRadius = BorderRadius.circular(xl);
}

/// Motion durations. Keep everything between 200–300ms.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 300);

  static const Curve curve = Curves.easeOutCubic;
}

/// Content width cap so desktop/tablet/web layouts stay readable.
abstract final class Layout {
  static const double maxContentWidth = 760;
}
