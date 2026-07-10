import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/hold_to_talk_mic_button.dart';
import 'package:app/features/questionnaire/domain/question.dart';

/// One full-screen question: label, a spacious always-visible answer field,
/// and a hold-to-talk microphone so typing and speaking fill the same box.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
    this.onSpeak,
    this.onVoiceSubmit,
  });

  final Question question;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  /// Replays the question aloud; the speaker button is hidden when null.
  final VoidCallback? onSpeak;

  /// Called with the finalized voice transcript once the user releases the
  /// mic - lets the page auto-advance without a separate "Далее" tap.
  final ValueChanged<String>? onVoiceSubmit;

  void _onVoiceText(String text) {
    controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A fixed-height header+field area on top, then the mic pinned to the
    // bottom of the available space (just above the Далее bar) regardless
    // of how short the question text is — not wherever it happens to fall
    // after a short ListView.
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x24, Insets.x20, Insets.x24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        question.required ? 'Обязательный вопрос' : 'Необязательно',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: question.required ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (onSpeak != null)
                      IconButton(
                        onPressed: onSpeak,
                        icon: const Icon(Icons.volume_up_rounded, size: 22),
                        tooltip: 'Озвучить вопрос',
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: Insets.x8),
                Text(question.fieldName, style: theme.textTheme.headlineSmall?.copyWith(height: 1.3)),
                const SizedBox(height: Insets.x24),
                Container(
                  padding: const EdgeInsets.all(Insets.x16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: Corners.lgRadius,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    autofocus: autofocus,
                    minLines: 1,
                    maxLines: 6,
                    style: theme.textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Ваш ответ…',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.x32),
          child: HoldToTalkMicButton(onTextChanged: _onVoiceText, onFinalResult: onVoiceSubmit, size: 96),
        ),
      ],
    );
  }
}
