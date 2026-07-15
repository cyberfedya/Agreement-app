import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/questionnaire/domain/interview_step.dart';

class InterviewStageBanner extends StatefulWidget {
  const InterviewStageBanner({super.key, required this.stage});

  final InterviewStage? stage;

  @override
  State<InterviewStageBanner> createState() => _InterviewStageBannerState();
}

class _InterviewStageBannerState extends State<InterviewStageBanner> {
  InterviewStage? _shown;
  InterviewStage? _justCompleted;
  Timer? _timer;

  /// Stage keys already shown at least once - lets a transition tell
  /// genuine forward progress from the user tapping "back" into a stage
  /// they already passed through. Only the former earns the "✓ just
  /// completed" checkmark; a back-navigation should read as a plain
  /// crossfade, never as re-completing a stage that isn't actually done.
  final Set<String> _seenKeys = {};

  @override
  void initState() {
    super.initState();
    _shown = widget.stage;
    if (_shown != null) _seenKeys.add(_shown!.key);
  }

  @override
  void didUpdateWidget(covariant InterviewStageBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _shown;
    final next = widget.stage;
    if (next?.key == previous?.key) return;

    _timer?.cancel();
    final isForwardProgress = previous != null && next != null && !_seenKeys.contains(next.key);
    if (next != null) _seenKeys.add(next.key);

    if (isForwardProgress) {
      setState(() {
        _justCompleted = previous;
        _shown = next;
      });
      _timer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _justCompleted = null);
      });
    } else {
      setState(() {
        _justCompleted = null;
        _shown = next;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = _justCompleted;
    final stage = _shown;
    if (stage == null && completed == null) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: completed != null
          ? _StageLine(
              key: ValueKey('done-${completed.key}'),
              text: '✓ ${completed.label}',
              color: theme.colorScheme.primary,
            )
          : stage != null
              ? _StageLine(
                  key: ValueKey('stage-${stage.key}'),
                  text: '${stage.icon} ${stage.label}',
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : const SizedBox.shrink(),
    );
  }
}

class _StageLine extends StatelessWidget {
  const _StageLine({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.x12),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
    );
  }
}
