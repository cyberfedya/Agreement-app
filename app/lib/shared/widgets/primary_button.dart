import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/shared/widgets/pressable_scale.dart';

/// Full-width primary CTA. Supports a disabled state (null [onPressed])
/// and an inline loading spinner.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? Row(
            key: const ValueKey('loading'),
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: Insets.x12),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          )
        : icon != null
            ? Row(
                key: const ValueKey('icon'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: Insets.x8),
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              )
            : Text(label, key: const ValueKey('label'), maxLines: 1, overflow: TextOverflow.ellipsis);

    return SizedBox(
      width: double.infinity,
      child: PressableScale(
        enabled: !loading && onPressed != null,
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          child: AnimatedSwitcher(duration: Motion.fast, child: child),
        ),
      ),
    );
  }
}
