import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/documents/domain/uploaded_document.dart';
import 'package:app/features/questionnaire/presentation/interview_script.dart';
import 'package:app/features/questionnaire/presentation/widgets/confidence_badge.dart';
import 'package:app/shared/animation/entrance.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// Post-OCR celebration: instead of jumping straight to the next question,
/// show the user exactly how much typing the AI just saved them - each
/// recognized field cascades in with a checkmark, then an honest "осталось
/// всего N деталей" sets up the rest of the interview.
class ExtractionCelebrationView extends StatelessWidget {
  const ExtractionCelebrationView({
    super.key,
    required this.title,
    required this.documents,
    required this.remainingQuestions,
    required this.warnings,
    required this.onContinue,
  });

  final String title;

  /// The just-processed upload batch (successful docs only are shown).
  final List<UploadedDocument> documents;

  /// Honest post-upload estimate, null when the preview call failed.
  final int? remainingQuestions;
  final List<String> warnings;
  final VoidCallback onContinue;

  static const int _maxShownFields = 6;

  /// Backend field keys are machine names ("enginenumber", "vin_code") -
  /// readable enough once underscores go and the first letter is upper.
  static String humanizeKey(String key) {
    final spaced = key.replaceAll('_', ' ').replaceAllMapped(RegExp('([a-zа-я])([A-ZА-Я])'), (m) => '${m[1]} ${m[2]}');
    if (spaced.isEmpty) return spaced;
    return spaced[0].toUpperCase() + spaced.substring(1).toLowerCase();
  }

  String get _remainingLine {
    final n = remainingQuestions;
    if (n == null) return 'Осталось уточнить лишь пару деталей.';
    if (n <= 0) return 'Вопросов не осталось — договор почти готов.';
    if (n == 1) return 'Осталась всего одна деталь.';
    if (n < 5) return 'Осталось всего $n детали.';
    return 'Осталось $n деталей.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fields = [
      for (final doc in documents.where((d) => d.isProcessed))
        for (final entry in doc.fields.entries) entry,
    ];
    final shown = fields.take(_maxShownFields).toList();
    final hiddenCount = fields.length - shown.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Insets.x24, Insets.x24, Insets.x24, Insets.x16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child:
                      Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary),
                            child: Icon(Icons.check_rounded, size: 36, color: theme.colorScheme.onPrimary),
                          )
                          .animate()
                          .scale(
                            begin: const Offset(0.4, 0.4),
                            end: const Offset(1, 1),
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          )
                          .fadeIn(duration: 250.ms),
                ),
                const SizedBox(height: Insets.x24),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(height: 1.25),
                  textAlign: TextAlign.center,
                ).animateEntranceStaggered(1),
                const SizedBox(height: Insets.x8),
                Text(
                  'Заполнил автоматически ${fields.length} ${_plural(fields.length)} — '
                  'вам не придётся вводить их вручную. $_remainingLine',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ).animateEntranceStaggered(2),
                if (InterviewScript.timeSavedLine(fields.length).isNotEmpty) ...[
                  const SizedBox(height: Insets.x4),
                  Text(
                    InterviewScript.timeSavedLine(fields.length),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                    textAlign: TextAlign.center,
                  ).animateEntranceStaggered(2),
                ],
                const SizedBox(height: Insets.x24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: Insets.x8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: Corners.lgRadius,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      for (final (index, entry) in shown.indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 18, color: theme.colorScheme.primary),
                                  const SizedBox(width: Insets.x12),
                                  Expanded(
                                    child: Text(
                                      humanizeKey(entry.key),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: Insets.x12),
                                  Flexible(
                                    child: Text(
                                      entry.value.value,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              // Only the "please double-check" case earns a
                              // line of its own - a reliable field is
                              // already communicated by the checkmark, so
                              // labelling every single row "reliable" would
                              // just be noise.
                              if (entry.value.confidence < InterviewScript.reliableConfidenceThreshold)
                                Padding(
                                  padding: const EdgeInsets.only(left: 30, top: 2),
                                  child: ConfidenceBadge(confidence: entry.value.confidence),
                                ),
                            ],
                          ),
                        ).animateEntranceStaggered(index + 3, step: const Duration(milliseconds: 70)),
                      if (hiddenCount > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: Insets.x8),
                          child: Text(
                            'и ещё $hiddenCount…',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ).animateEntranceStaggered(shown.length + 3),
                    ],
                  ),
                ),
                for (final warning in warnings) ...[
                  const SizedBox(height: Insets.x12),
                  Container(
                    padding: const EdgeInsets.all(Insets.x12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: Corners.mdRadius,
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: Insets.x8),
                        Expanded(
                          child: Text(
                            warning,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ).animateEntranceStaggered(shown.length + 4),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Insets.x24, 0, Insets.x24, Insets.x24),
          child: PrimaryButton(label: 'Продолжить', onPressed: onContinue).animateEntranceStaggered(4),
        ),
      ],
    );
  }

  static String _plural(int n) {
    final mod10 = n % 10, mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'поле';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'поля';
    return 'полей';
  }
}
