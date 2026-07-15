import 'package:flutter/material.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/hold_to_talk_mic_button.dart';
import 'package:app/features/questionnaire/presentation/widgets/voice_wave.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/shared/widgets/pressable_scale.dart';
enum _ComposerMode { idle, listening, confirm }
class AnswerComposer extends StatefulWidget {
  const AnswerComposer({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.onAttach,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  final VoidCallback? onAttach;
  final bool enabled;

  @override
  State<AnswerComposer> createState() => _AnswerComposerState();
}

class _AnswerComposerState extends State<AnswerComposer> {
  _ComposerMode _mode = _ComposerMode.idle;
  String _transcript = '';
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _onListeningChanged(bool listening) {
    if (listening) {
      setState(() {
        _mode = _ComposerMode.listening;
        _transcript = '';
      });
      return;
    }
    if (_mode == _ComposerMode.listening && _transcript.trim().isEmpty) {
      setState(() => _mode = _ComposerMode.idle);
    }
  }

  void _onVoiceFinal(String text) {
    setState(() {
      _transcript = text;
      _mode = _ComposerMode.confirm;
    });
  }

  void _confirmVoice() {
    final text = _transcript.trim();
    setState(() => _mode = _ComposerMode.idle);
    if (text.isNotEmpty) widget.onSubmit(text);
  }

  void _editVoice() {
    widget.controller.value = TextEditingValue(
      text: _transcript,
      selection: TextSelection.collapsed(offset: _transcript.length),
    );
    setState(() => _mode = _ComposerMode.idle);
  }

  void _submitTyped() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return AnimatedSize(
      duration: Motion.normal,
      curve: Motion.curve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: Motion.fast,
        switchInCurve: Motion.curve,
        switchOutCurve: Motion.curve,
        child: switch (_mode) {
          _ComposerMode.confirm => _buildConfirm(theme, l10n),
          _ => _buildInput(theme, l10n),
        },
      ),
    );
  }

  /// Idle + listening share one surface so the wave appears *inside* the
  /// field the user was about to type into - voice is not a separate UI.
  Widget _buildInput(ThemeData theme, AppLocalizations l10n) {
    final listening = _mode == _ComposerMode.listening;
    return Container(
      key: const ValueKey('input'),
      padding: const EdgeInsets.fromLTRB(Insets.x16, Insets.x8, Insets.x8, Insets.x8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: Corners.x2lRadius,
        border: Border.all(
          color: listening ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: listening ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: listening
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: Insets.x8),
                    child: Row(
                      children: [
                        const VoiceWave(height: 26),
                        const SizedBox(width: Insets.x12),
                        Expanded(
                          child: Text(
                            _transcript.isEmpty ? l10n.questionnaireListening : _transcript,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _transcript.isEmpty
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : TextField(
                    controller: widget.controller,
                    enabled: widget.enabled,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitTyped(),
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: l10n.questionnaireSpeakOrType,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: Insets.x12),
                      isDense: true,
                    ),
                  ),
          ),
          if (!listening && widget.onAttach != null)
            IconButton(
              onPressed: widget.enabled ? widget.onAttach : null,
              icon: const Icon(Icons.attach_file_rounded, size: 22),
              tooltip: l10n.questionnaireAttachDocument,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          const SizedBox(width: Insets.x4),
          AnimatedSwitcher(
            duration: Motion.fast,
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: _hasText && !listening
                ? PressableScale(
                    key: const ValueKey('send'),
                    child: IconButton.filled(
                      onPressed: widget.enabled ? _submitTyped : null,
                      icon: const Icon(Icons.arrow_upward_rounded, size: 22),
                      tooltip: l10n.questionnaireSend,
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                  )
                : HoldToTalkMicButton(
                    key: const ValueKey('mic'),
                    size: 44,
                    onTextChanged: (text) => setState(() => _transcript = text),
                    onFinalResult: _onVoiceFinal,
                    onListeningChanged: _onListeningChanged,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirm(ThemeData theme, AppLocalizations l10n) {
    return Container(
      key: const ValueKey('confirm'),
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
          Text('«${_transcript.trim()}»', style: theme.textTheme.titleMedium),
          const SizedBox(height: Insets.x12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: widget.enabled ? _confirmVoice : null,
                  child: Text(l10n.questionnaireConfirm),
                ),
              ),
              const SizedBox(width: Insets.x8),
              OutlinedButton(onPressed: _editVoice, child: Text(l10n.questionnaireEditAnswer)),
            ],
          ),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _mode = _ComposerMode.idle),
              child: Text(l10n.questionnaireSayAgain),
            ),
          ),
        ],
      ),
    );
  }
}
