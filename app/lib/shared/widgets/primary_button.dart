import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';

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
              Text(label),
            ],
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(icon, size: 18), const SizedBox(width: Insets.x8), Text(label)],
              )
            : Text(label);

    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: loading ? null : onPressed, child: child),
    );
  }
}
