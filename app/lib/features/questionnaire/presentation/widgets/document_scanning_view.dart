import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:app/core/theme/app_tokens.dart';

/// Full-area "the AI is reading your document" state: a breathing document
/// icon with a sweeping scan line and rotating status phrases. Shown while
/// the upload+OCR round-trip runs (several seconds), so the wait reads as
/// work happening rather than a frozen screen.
class DocumentScanningView extends StatefulWidget {
  const DocumentScanningView({super.key, required this.steps});

  /// Phrases to rotate through, in order, looping.
  final List<String> steps;

  @override
  State<DocumentScanningView> createState() => _DocumentScanningViewState();
}

class _DocumentScanningViewState extends State<DocumentScanningView> {
  Timer? _timer;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (mounted) setState(() => _step = (_step + 1) % widget.steps.length);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 96,
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 84,
                  height: 104,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: Corners.mdRadius,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Icon(Icons.description_outlined, size: 36, color: theme.colorScheme.primary),
                ),
                // Scan line sweeping top -> bottom on loop.
                Container(
                      width: 92,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: theme.colorScheme.primary,
                        boxShadow: [
                          BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.4), blurRadius: 12),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .moveY(begin: -48, end: 48, duration: 1400.ms, curve: Curves.easeInOutCubic)
                    .fade(begin: 0.4, end: 1, duration: 700.ms),
              ],
            ),
          ),
          const SizedBox(height: Insets.x24),
          AnimatedSwitcher(
            duration: Motion.fast,
            child: Text(
              widget.steps[_step],
              key: ValueKey(_step),
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
