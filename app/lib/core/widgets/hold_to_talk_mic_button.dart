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
    this.onPermissionDenied,
    this.onRecognitionError,
    this.onNoSpeechDetected,
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

  /// The user denied (or has permanently blocked) microphone access - the
  /// button did nothing when pressed, and without this callback the caller
  /// has no way to tell the user why.
  final VoidCallback? onPermissionDenied;

  /// The recognizer itself failed (native engine error, no network for a
  /// cloud-backed recognizer, etc.) - distinct from simply hearing nothing.
  final VoidCallback? onRecognitionError;

  /// Listening ended with no words recognized at all - the mic worked, but
  /// nothing was heard (silence, background noise). Distinct from
  /// [onRecognitionError] so the caller can give a more specific hint
  /// ("didn't catch that" vs. "microphone isn't working").
  final VoidCallback? onNoSpeechDetected;

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

  /// Whether any (even partial) words were recognized during the current
  /// press - lets [_onStatus] tell "nothing was heard" apart from a normal
  /// stop after real speech, without needing extra state threading through
  /// `onResult`.
  bool _heardAnything = false;

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
    if (!mounted) return;
    if (!granted) {
      widget.onPermissionDenied?.call();
      return;
    }

    _heardAnything = false;

    if (!_initialized) {
      _initialized = await _speech.initialize(onStatus: _onStatus, onError: _onError);
      if (!mounted) return;
      if (!_initialized) {
        widget.onRecognitionError?.call();
        return;
      }
    }

    _setListening(true);
    await _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.trim().isNotEmpty) _heardAnything = true;
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
      if (!mounted) return;
      final wasListening = _listening;
      _setListening(false);
      if (wasListening && !_heardAnything) widget.onNoSpeechDetected?.call();
    }
  }

  void _onError(dynamic error) {
    // A permanent error can leave the recognizer unusable until it's
    // re-initialized - reset so the next press starts clean instead of
    // silently doing nothing forever.
    _initialized = false;
    if (!mounted) return;
    final wasListening = _listening;
    _setListening(false);
    if (wasListening) widget.onRecognitionError?.call();
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
