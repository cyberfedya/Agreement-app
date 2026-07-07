import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';

/// A softly pulsing placeholder block used while content loads.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = Corners.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 1.0,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(widget.radius)),
      ),
    );
  }
}

/// Skeleton stand-in for an [AgreementCard] while the list loads.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.x16),
        child: Row(
          children: [
            const Skeleton(width: 44, height: 44, radius: Corners.sm),
            const SizedBox(width: Insets.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Skeleton(width: 220, height: 14),
                  SizedBox(height: Insets.x8),
                  Skeleton(width: 140, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-page list of skeleton cards.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Insets.x20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: Insets.x12),
      itemBuilder: (_, _) => const SkeletonCard(),
    );
  }
}
