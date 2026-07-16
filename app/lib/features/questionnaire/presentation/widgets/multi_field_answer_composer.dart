import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/hold_to_talk_mic_button.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/features/questionnaire/presentation/widgets/voice_wave.dart';
import 'package:app/l10n/app_localizations.dart';

enum _MicMode { idle, listening, confirm }

/// Renders one small labeled box per field of a combined question (e.g.
/// VIN + engine + body + chassis) instead of a single free-text blob.
/// Boxes can be filled manually, all at once by voice (the AI distributes
/// one spoken blob across the right boxes), or by document upload (OCR
/// fills every matching box) - partial answers are fine, unfilled boxes
/// just stay empty and editable.
class MultiFieldAnswerComposer extends StatefulWidget {
  const MultiFieldAnswerComposer({
    super.key,
    required this.fields,
    required this.initialValues,
    required this.onSubmit,
    this.onAttach,
    this.enabled = true,
  });

  final List<Question> fields;

  /// Current known value per field id (from `displayValues`) - used to
  /// pre-fill/auto-fill boxes the user hasn't typed into themselves.
  final Map<int, String> initialValues;

  /// Called with one combined natural-language string built from whichever
  /// boxes are non-empty - the caller (`submitGroupAnswer`) hands this
  /// straight to the backend's own per-field extraction.
  final ValueChanged<String> onSubmit;

  final VoidCallback? onAttach;
  final bool enabled;

  @override
  State<MultiFieldAnswerComposer> createState() => _MultiFieldAnswerComposerState();
}

class _MultiFieldAnswerComposerState extends State<MultiFieldAnswerComposer> {
  final Map<int, TextEditingController> _controllers = {};
  final Set<int> _justFilled = {};
  _MicMode _micMode = _MicMode.idle;
  String _transcript = '';

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant MultiFieldAnswerComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  void _syncControllers() {
    for (final field in widget.fields) {
      final value = widget.initialValues[field.fieldId];
      final controller = _controllers.putIfAbsent(field.fieldId, () => TextEditingController(text: value ?? ''));
      // Only auto-fill a box that's still empty - never overwrite what the
      // user already typed, and never guess a value for it.
      if (controller.text.trim().isEmpty && value != null && value.trim().isNotEmpty) {
        controller.text = value;
        _justFilled.add(field.fieldId);
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) setState(() => _justFilled.remove(field.fieldId));
        });
      }
    }
    // Drop controllers for fields no longer in this group (shouldn't
    // normally happen mid-turn, but keeps this defensive).
    _controllers.removeWhere((fieldId, controller) {
      final stale = widget.fields.every((f) => f.fieldId != fieldId);
      if (stale) controller.dispose();
      return stale;
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final parts = <String>[];
    for (final field in widget.fields) {
      final value = _controllers[field.fieldId]?.text.trim() ?? '';
      if (value.isNotEmpty) parts.add('${field.fieldName}: $value.');
    }
    if (parts.isEmpty) return;
    widget.onSubmit(parts.join(' '));
  }

  void _onListeningChanged(bool listening) {
    if (listening) {
      setState(() {
        _micMode = _MicMode.listening;
        _transcript = '';
      });
      return;
    }
    if (_micMode == _MicMode.listening && _transcript.trim().isEmpty) {
      setState(() => _micMode = _MicMode.idle);
    }
  }

  void _onVoiceFinal(String text) {
    setState(() {
      _transcript = text;
      _micMode = _MicMode.confirm;
    });
  }

  void _confirmVoice() {
    final text = _transcript.trim();
    setState(() => _micMode = _MicMode.idle);
    if (text.isNotEmpty) widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_micMode == _MicMode.confirm) {
      return _VoiceConfirmCard(
        transcript: _transcript,
        onConfirm: widget.enabled ? _confirmVoice : null,
        onEdit: () => setState(() => _micMode = _MicMode.idle),
      );
    }

    final listening = _micMode == _MicMode.listening;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (listening)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Insets.x12),
            child: Row(
              children: [
                const VoiceWave(height: 26),
                const SizedBox(width: Insets.x12),
                Expanded(
                  child: Text(
                    _transcript.isEmpty ? l10n.questionnaireListening : _transcript,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          )
        else
          for (final field in widget.fields) ...[
            _FieldBox(
              field: field,
              controller: _controllers[field.fieldId]!,
              enabled: widget.enabled,
              highlighted: _justFilled.contains(field.fieldId),
              onSubmitted: _submit,
            ),
            const SizedBox(height: Insets.x12),
          ],
        if (!listening)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.onAttach != null)
                IconButton(
                  onPressed: widget.enabled ? widget.onAttach : null,
                  icon: const Icon(Icons.attach_file_rounded, size: 22),
                  tooltip: l10n.questionnaireAttachDocument,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              else
                const SizedBox.shrink(),
              HoldToTalkMicButton(
                size: 64,
                onTextChanged: (text) => setState(() => _transcript = text),
                onFinalResult: _onVoiceFinal,
                onListeningChanged: _onListeningChanged,
              ),
            ],
          ),
      ],
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({
    required this.field,
    required this.controller,
    required this.enabled,
    required this.highlighted,
    required this.onSubmitted,
  });

  final Question field;
  final TextEditingController controller;
  final bool enabled;
  final bool highlighted;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: Motion.normal,
      curve: Motion.curve,
      decoration: BoxDecoration(
        borderRadius: Corners.smRadius,
        color: highlighted ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35) : Colors.transparent,
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        minLines: 1,
        maxLines: 2,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onSubmitted(),
        decoration: InputDecoration(labelText: field.fieldName),
      ),
    );
  }
}

class _VoiceConfirmCard extends StatelessWidget {
  const _VoiceConfirmCard({required this.transcript, required this.onConfirm, required this.onEdit});

  final String transcript;
  final VoidCallback? onConfirm;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(Insets.x16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: Corners.x2lRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.questionnaireIUnderstood,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: Insets.x4),
          Text('«${transcript.trim()}»', style: theme.textTheme.titleMedium),
          const SizedBox(height: Insets.x12),
          Row(
            children: [
              Expanded(child: FilledButton(onPressed: onConfirm, child: Text(l10n.questionnaireConfirm))),
              const SizedBox(width: Insets.x8),
              OutlinedButton(onPressed: onEdit, child: Text(l10n.questionnaireEditAnswer)),
            ],
          ),
        ],
      ),
    );
  }
}
