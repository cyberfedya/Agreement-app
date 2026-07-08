import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:app/core/services/permission_service.dart';
import 'package:app/core/theme/app_tokens.dart';

/// Press-and-hold microphone. Recording starts on press, transcribes live,
/// and stops the instant the finger lifts — no separate start/stop taps.
class HoldToTalkMicButton extends StatefulWidget {
  const HoldToTalkMicButton({
    super.key,
    required this.onTextChanged,
    this.permissionService,
    this.size = 72,
  });

  /// Called with the live-recognized text as speech is transcribed.
  final ValueChanged<String> onTextChanged;
  final PermissionService? permissionService;
  final double size;

  @override
  State<HoldToTalkMicButton> createState() => _HoldToTalkMicButtonState();
}

class _HoldToTalkMicButtonState extends State<HoldToTalkMicButton> {
  late final PermissionService _permissions = widget.permissionService ?? DevicePermissionService();
  final SpeechToText _speech = SpeechToText();
  bool _listening = false;
  bool _available = false;

  @override
  void dispose() {
    if (_listening) _speech.stop();
    super.dispose();
  }

  Future<void> _start() async {
    final granted = await _permissions.requestMicrophone();
    if (!granted || !mounted) return;

    _available = await _speech.initialize(onStatus: _onStatus, onError: (_) {});
    if (!_available || !mounted) return;

    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) => widget.onTextChanged(result.recognizedWords),
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (mounted) setState(() => _listening = false);
    }
  }

  Future<void> _stop() async {
    if (!_listening) return;
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onLongPressStart: (_) => _start(),
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.curve,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _listening ? scheme.primary : scheme.primaryContainer,
          boxShadow: _listening
              ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 4)]
              : null,
        ),
        child: Icon(
          _listening ? Icons.mic : Icons.mic_none_rounded,
          color: _listening ? scheme.onPrimary : scheme.onPrimaryContainer,
          size: widget.size * 0.42,
        ),
      ),
    );
  }
}
