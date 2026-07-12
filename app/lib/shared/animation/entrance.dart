import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Consistent "appear" motion for screen content - one shared vocabulary
/// instead of every screen improvising its own fade/slide numbers.
extension ScreenEntrance on Widget {
  /// Fade + subtle rise, used for a screen's whole primary content block.
  Widget animateEntrance({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .fadeIn(duration: 320.ms, curve: Curves.easeOut)
        .slideY(begin: 0.04, end: 0, duration: 320.ms, curve: Curves.easeOut);
  }

  /// Same motion, staggered by [index] - use on items inside a list/column
  /// so they cascade in one after another instead of popping in at once.
  Widget animateEntranceStaggered(int index, {Duration step = const Duration(milliseconds: 40)}) {
    return animateEntrance(delay: step * index);
  }
}
