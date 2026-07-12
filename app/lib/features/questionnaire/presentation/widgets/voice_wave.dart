import 'dart:math';

import 'package:flutter/material.dart';

/// Fluid bar wave shown while the mic is held - the visual promise that
/// the assistant is listening. Purely decorative (not tied to actual audio
/// levels), phase-shifted sines keep it organic instead of mechanical.
class VoiceWave extends StatefulWidget {
  const VoiceWave({super.key, this.height = 32, this.color});

  final double height;
  final Color? color;

  @override
  State<VoiceWave> createState() => _VoiceWaveState();
}

class _VoiceWaveState extends State<VoiceWave> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * pi;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Container(
                  width: 4,
                  // Middle bars swing wider than the edges, like a real
                  // waveform envelope.
                  height: widget.height * (0.30 + 0.70 * (0.5 + 0.5 * sin(t * 2 - i * 1.1)) * (1 - (i - 2).abs() * 0.18)),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                ),
              ),
          ],
        );
      },
    );
  }
}
