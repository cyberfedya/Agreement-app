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
  static const double x2l = 28;

  static final BorderRadius smRadius = BorderRadius.circular(sm);
  static final BorderRadius mdRadius = BorderRadius.circular(md);
  static final BorderRadius lgRadius = BorderRadius.circular(lg);
  static final BorderRadius xlRadius = BorderRadius.circular(xl);
  static final BorderRadius x2lRadius = BorderRadius.circular(x2l);
}

/// Motion durations. Keep UI transitions between 200–300ms.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 300);

  /// Minimum time the "Обновляю договор…" thinking state stays visible
  /// after an answer, even when the backend replies instantly - the pause
  /// is what makes the assistant feel like it actually did something.
  static const Duration thinkingMin = Duration(milliseconds: 450);

  static const Curve curve = Curves.easeOutCubic;

  /// For hero moments (progress bar sweeps, celebration reveals) that
  /// deserve a longer, softer settle than the standard [curve].
  static const Curve emphasized = Curves.easeOutQuint;

  /// Per-step reveal pace for the premium "Проверяю ответы → Формирую
  /// структуру → …" generation sequence - deliberately short (300–500ms
  /// range from the spec) so a fast backend response never feels like a
  /// manufactured wait.
  static const Duration generationStep = Duration(milliseconds: 320);
}

/// Content width cap so desktop/tablet/web layouts stay readable.
abstract final class Layout {
  static const double maxContentWidth = 760;
}
