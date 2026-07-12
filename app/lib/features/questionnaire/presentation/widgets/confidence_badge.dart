import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/questionnaire/presentation/interview_script.dart';

/// A colored-dot + label reading of a backend-supplied OCR confidence
/// value: green "Надёжно распознано" above
/// [InterviewScript.reliableConfidenceThreshold], amber "Проверьте это
/// значение" below it. Presentation only - the threshold and the number
/// itself both come from [InterviewScript]/the backend, this widget just
/// draws them.
class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({super.key, required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reliable = confidence >= InterviewScript.reliableConfidenceThreshold;
    // Deliberately not the primary/error palette - a review flag isn't a
    // brand color and isn't an error, it's a distinct amber "take a look".
    final color = reliable ? const Color(0xFF2E9B5C) : const Color(0xFFB8860B);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: Insets.x4 + 2),
        Text(
          InterviewScript.confidenceLabel(confidence),
          style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
