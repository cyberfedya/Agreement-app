import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/questionnaire/presentation/widgets/thinking_indicator.dart';

/// The interview's opening beat: the assistant introduces itself and
/// explains what will happen ("заполню всё сам, спрошу только недостающее")
/// while the planner's first step loads behind it - the greeting *is* the
/// loading state, so the user never sees a skeleton.
class GreetingView extends StatelessWidget {
  const GreetingView({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.x24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A quietly breathing dot - presence, not decoration.
          Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.25, 1.25), duration: 900.ms, curve: Curves.easeInOut)
              .fade(begin: 0.7, end: 1, duration: 900.ms),
          const SizedBox(height: Insets.x24),
          Text(title, style: theme.textTheme.headlineMedium?.copyWith(height: 1.2))
              .animate(delay: 150.ms)
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .slideY(begin: 0.06, end: 0, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: Insets.x16),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
          ).animate(delay: 450.ms).fadeIn(duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: Insets.x40),
          const ThinkingIndicator(label: 'Готовлю первый шаг…').animate(delay: 800.ms).fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
}
