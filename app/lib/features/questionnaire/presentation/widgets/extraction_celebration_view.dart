import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:app/core/localization/backend_phrases.dart';
import 'package:app/core/sound/app_sound.dart';
import 'package:app/core/sound/sound_service.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/documents/domain/uploaded_document.dart';
import 'package:app/features/questionnaire/presentation/interview_script.dart';
import 'package:app/features/questionnaire/presentation/widgets/confidence_badge.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/shared/animation/entrance.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// Post-OCR celebration: instead of jumping straight to the next question,
/// show the user exactly how much typing the AI just saved them - each
/// recognized field reveals one at a time (not a fast burst) with a tick
/// sound, so it reads as the AI genuinely finding one fact after another,
/// then an honest "осталось всего N деталей" sets up the rest of the
/// interview.
class ExtractionCelebrationView extends StatefulWidget {
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

  @override
  State<ExtractionCelebrationView> createState() => _ExtractionCelebrationViewState();
}

class _ExtractionCelebrationViewState extends State<ExtractionCelebrationView> {
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
    final total = widget.documents
        .where((d) => d.isProcessed)
        .fold(0, (sum, d) => sum + d.fields.length)
        .clamp(0, ExtractionCelebrationView._maxShownFields);
    if (_visibleCount >= total) return;
    setState(() => _visibleCount++);
    unawaited(context.read<SoundService>().play(AppSound.tick));
    if (_visibleCount < total) {
      _timer = Timer(const Duration(milliseconds: 380), _revealNext);
    }
  }

  String _remainingLine(AppLocalizations l10n) {
    final n = widget.remainingQuestions;
    if (n == null) return l10n.extractionRemainingUnknown;
    if (n <= 0) return l10n.extractionRemainingNone;
    if (n == 1) return l10n.extractionRemainingOne;
    if (n < 5) return l10n.extractionRemainingFew(n);
    return l10n.extractionRemainingMany(n);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final fields = [
      for (final doc in widget.documents.where((d) => d.isProcessed))
        for (final entry in doc.fields.entries) entry,
    ];
    final shown = fields.take(ExtractionCelebrationView._maxShownFields).toList();
    final revealed = shown.take(_visibleCount).toList();
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
                  widget.title,
                  style: theme.textTheme.headlineSmall?.copyWith(height: 1.25),
                  textAlign: TextAlign.center,
                ).animateEntranceStaggered(1),
                const SizedBox(height: Insets.x8),
                Text(
                  l10n.extractionFilledSummary(
                    fields.length,
                    _plural(fields.length, l10n),
                    _remainingLine(l10n),
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ).animateEntranceStaggered(2),
                if (InterviewScript.timeSavedLine(fields.length, l10n).isNotEmpty) ...[
                  const SizedBox(height: Insets.x4),
                  Text(
                    InterviewScript.timeSavedLine(fields.length, l10n),
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
                      // Revealed one at a time (not all at once) - see
                      // _revealNext - so it reads as the AI genuinely
                      // finding one fact after another, each with its own
                      // fade-in the moment it appears.
                      for (final entry in revealed)
                        Padding(
                          key: ValueKey(entry.key),
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
                                      localizeDocumentFieldKey(entry.key),
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
                        ).animateEntrance(),
                      if (hiddenCount > 0 && _visibleCount >= shown.length)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: Insets.x8),
                          child: Text(
                            l10n.extractionAndMore(hiddenCount),
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ).animateEntrance(),
                    ],
                  ),
                ),
                for (final warning in widget.warnings) ...[
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
          child: PrimaryButton(label: l10n.extractionContinue, onPressed: widget.onContinue).animateEntranceStaggered(4),
        ),
      ],
    );
  }

  static String _plural(int n, AppLocalizations l10n) {
    final mod10 = n % 10, mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return l10n.extractionPluralFieldOne;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return l10n.extractionPluralFieldFew;
    return l10n.extractionPluralFieldMany;
  }
}
