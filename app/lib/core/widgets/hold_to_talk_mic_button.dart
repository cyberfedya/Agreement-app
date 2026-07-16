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
    this.onFinalResult,
    this.onListeningChanged,
    this.permissionService,
    this.size = 72,
  });

  /// Called with the live-recognized text as speech is transcribed.
  final ValueChanged<String> onTextChanged;

  /// Called once with the finalized transcript when recognition settles
  /// after the user releases the button - lets the caller auto-advance
  /// without waiting for a separate confirmation tap.
  final ValueChanged<String>? onFinalResult;

  /// Fires when recording starts/stops, so the surrounding UI can swap
  /// itself into a "Слушаю…" state while the mic is held.
  final ValueChanged<bool>? onListeningChanged;
  final PermissionService? permissionService;
  final double size;

  @override
  State<HoldToTalkMicButton> createState() => _HoldToTalkMicButtonState();
}

class _HoldToTalkMicButtonState extends State<HoldToTalkMicButton> {
  late final PermissionService _permissions = widget.permissionService ?? DevicePermissionService();
  final SpeechToText _speech = SpeechToText();
  bool _listening = false;
  bool _initialized = false;

  void _setListening(bool value) {
    if (_listening == value) return;
    setState(() => _listening = value);
    widget.onListeningChanged?.call(value);
  }

  @override
  void dispose() {
    if (_listening) _speech.stop();
    super.dispose();
  }

  Future<void> _start() async {
    final granted = await _permissions.requestMicrophone();
    if (!granted || !mounted) return;

    // Initialize the recognizer once and reuse it - re-initializing on every
    // press tears down and rebuilds the native engine each time, which is
    // what causes the "starts then immediately cuts off, then never starts
    // again" behavior on some devices.
    if (!_initialized) {
      _initialized = await _speech.initialize(onStatus: _onStatus, onError: _onError);
      if (!_initialized || !mounted) return;
    }

    _setListening(true);
    await _speech.listen(
      onResult: (result) {
        widget.onTextChanged(result.recognizedWords);
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          widget.onFinalResult?.call(result.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        pauseFor: const Duration(seconds: 6),
        listenFor: const Duration(minutes: 2),
      ),
    );
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (mounted) _setListening(false);
    }
  }

  void _onError(dynamic error) {
    // A permanent error can leave the recognizer unusable until it's
    // re-initialized - reset so the next press starts clean instead of
    // silently doing nothing forever.
    _initialized = false;
    if (mounted) _setListening(false);
  }

  Future<void> _stop() async {
    if (!_listening) return;
    await _speech.stop();
    if (mounted) _setListening(false);
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
