import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/shared/widgets/pressable_scale.dart';

/// Interview top bar: no "Вопрос N" anywhere. A meaningful status line
/// ("Осталось две детали"), a live progress bar that sweeps forward after
/// every answer, and the live-document chip that shows the agreement
/// growing in real time.
class InterviewHeader extends StatelessWidget {
  const InterviewHeader({
    super.key,
    required this.title,
    required this.status,
    required this.progress,
    required this.onOpenDocument,
    this.onBack,
    this.estimate,
  });

  final String title;
  final String status;

  /// "≈ 2 вопроса · ~30 сек" - the backend's own remaining-questions
  /// count, formatted; null when the backend hasn't given one yet (e.g.
  /// the very first question). Shown as a quiet factual line under the
  /// warmer [status] phrase, never replacing it.
  final String? estimate;

  /// 0..1 share of the agreement considered ready. Animated on change.
  final double progress;
  final VoidCallback onOpenDocument;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.x12, Insets.x8, Insets.x20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                tooltip: 'Предыдущий шаг',
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: Motion.fast,
                      switchInCurve: Motion.curve,
                      switchOutCurve: Motion.curve,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        status,
                        key: ValueKey(status),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    if (estimate != null) ...[
                      const SizedBox(height: 1),
                      AnimatedSwitcher(
                        duration: Motion.fast,
                        child: Text(
                          estimate!,
                          key: ValueKey(estimate),
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Insets.x8),
              PressableScale(
                child: Material(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: Corners.x2lRadius,
                  child: InkWell(
                    borderRadius: Corners.x2lRadius,
                    onTap: onOpenDocument,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Insets.x12, vertical: Insets.x8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description_outlined, size: 16, color: theme.colorScheme.onPrimaryContainer),
                          const SizedBox(width: Insets.x4 + 2),
                          // Keyed by percent so each step re-runs the tween
                          // and the number feels alive, not static.
                          TweenAnimationBuilder<double>(
                            key: ValueKey(percent),
                            tween: Tween(begin: 0.85, end: 1),
                            duration: Motion.normal,
                            curve: Motion.emphasized,
                            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                            child: Text(
                              '$percent%',
                              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.x12),
          Padding(
            padding: const EdgeInsets.only(left: Insets.x8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0, 1)),
                duration: const Duration(milliseconds: 600),
                curve: Motion.emphasized,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 3,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
