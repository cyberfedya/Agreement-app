import 'dart:math';

import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';

/// "Обновляю договор…" beat shown between an answer and the next question:
/// three softly breathing dots plus a rotating phrase. Deliberately quiet -
/// it communicates work, it doesn't perform it.
class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key, required this.label});

  final String label;

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: Insets.x4),
                    child: Opacity(
                      // Each dot breathes on a phase-shifted sine wave.
                      opacity: 0.35 + 0.65 * (0.5 + 0.5 * sin((_controller.value * 2 * pi) - i * 0.9)),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: Insets.x8),
        Text(
          widget.label,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
