import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:app/core/theme/app_tokens.dart';

/// The premium "building your agreement" sequence shown between tapping
/// "Создать договор" and the agreement screen: a short checklist that
/// steps forward on its own pace ([Motion.generationStep] per item),
/// independent of how fast the real `generate` call actually returns.
///
/// This is pure pacing, not a progress bar for the network call - the
/// parent is responsible for keeping this mounted at least as long as the
/// sequence takes (so a fast backend never flashes past it) and for
/// navigating away once the real result is in. If the backend is slower
/// than the sequence, the last step just holds with a gentle pulse rather
/// than freezing.
class GenerationSequenceView extends StatefulWidget {
  const GenerationSequenceView({super.key, required this.steps});

  final List<String> steps;

  @override
  State<GenerationSequenceView> createState() => _GenerationSequenceViewState();
}

class _GenerationSequenceViewState extends State<GenerationSequenceView> {
  Timer? _timer;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Motion.generationStep, (timer) {
      if (_activeIndex >= widget.steps.length - 1) {
        timer.cancel();
        return;
      }
      setState(() => _activeIndex++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.x32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (index, step) in widget.steps.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Insets.x8),
                child: Row(
                  children: [
                    _StepIndicator(state: _stateFor(index)),
                    const SizedBox(width: Insets.x12),
                    Expanded(
                      child: Text(
                        step,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: index <= _activeIndex ? theme.colorScheme.onSurface : theme.colorScheme.outline,
                          fontWeight: index == _activeIndex ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms),
          ],
        ),
      ),
    );
  }

  _StepState _stateFor(int index) {
    if (index < _activeIndex) return _StepState.done;
    if (index == _activeIndex) return _StepState.active;
    return _StepState.pending;
  }
}

enum _StepState { pending, active, done }

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.state});

  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: Motion.fast,
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: switch (state) {
        _StepState.done => Container(
          key: const ValueKey('done'),
          width: 22,
          height: 22,
          decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary),
          child: Icon(Icons.check_rounded, size: 14, color: theme.colorScheme.onPrimary),
        ),
        _StepState.active => SizedBox(
          key: const ValueKey('active'),
          width: 22,
          height: 22,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
            ),
          ),
        ),
        _StepState.pending => Container(
          key: const ValueKey('pending'),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.5),
          ),
        ),
      },
    );
  }
}
