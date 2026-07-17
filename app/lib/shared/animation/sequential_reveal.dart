import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/shared/animation/entrance.dart';

/// One field/value pair to reveal.
typedef RevealItem = ({String label, String value});

/// Reveals [items] one row at a time, [stepDelay] apart - unlike
/// [ScreenEntrance.animateEntranceStaggered] (which starts every item's
/// animation at build time with an offset delay, so later items can still
/// be mid-fade while earlier ones finish), this widget only builds/starts
/// the next row once the previous one's own entrance animation has settled,
/// so it genuinely reads as the AI finding one fact after another rather
/// than a fast cascade. [onItemRevealed] fires once per row (e.g. to play
/// a tick sound) - never fires more than [items.length] times, and never
/// fires again if the widget is disposed mid-sequence.
class SequentialReveal extends StatefulWidget {
  const SequentialReveal({
    super.key,
    required this.items,
    this.stepDelay = const Duration(milliseconds: 380),
    this.onItemRevealed,
  });

  final List<RevealItem> items;
  final Duration stepDelay;
  final ValueChanged<RevealItem>? onItemRevealed;

  @override
  State<SequentialReveal> createState() => _SequentialRevealState();
}

class _SequentialRevealState extends State<SequentialReveal> {
  int _visibleCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _revealNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _revealNext() {
    if (_visibleCount >= widget.items.length) return;
    final item = widget.items[_visibleCount];
    setState(() => _visibleCount++);
    widget.onItemRevealed?.call(item);
    if (_visibleCount < widget.items.length) {
      _timer = Timer(widget.stepDelay, _revealNext);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _visibleCount; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Insets.x4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: Insets.x8),
                Text(widget.items[i].label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(width: Insets.x4),
                Text(
                  widget.items[i].value,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ).animateEntrance(),
      ],
    );
  }
}
