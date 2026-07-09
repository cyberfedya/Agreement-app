import 'package:flutter_tts/flutter_tts.dart';

import 'package:app/core/services/cloud_tts_service.dart';

/// Speaks interview questions aloud. Tries the premium Cloud voice first
/// (Chirp3-HD Charon, Russian — requires GOOGLE_TTS_KEY at build time) and
/// falls back to the device's own TTS engine with a lowered pitch when the
/// cloud path is unavailable or fails.
///
/// Every call is best-effort: TTS must never break the interview, so all
/// engine errors are swallowed.
class TtsService {
  TtsService();

  // Created lazily: just_audio's player binds platform channels on
  // construction, which don't exist in widget tests.
  CloudTtsService? _cloud;
  final FlutterTts _device = FlutterTts();

  Future<void> speak(String text, {String lang = 'ru'}) async {
    if (text.trim().isEmpty) return;

    try {
      _cloud ??= CloudTtsService();
      if (await _cloud!.speakForLanguage(text, lang)) return;
    } catch (_) {
      // fall through to on-device TTS
    }

    try {
      await _device.stop();
      await _device.setLanguage(switch (lang) {
        'ru' => 'ru-RU',
        'uz' => 'uz-UZ',
        _ => 'en-US',
      });
      // No male on-device voice is guaranteed; a lower pitch approximates one.
      await _device.setPitch(0.8);
      await _device.speak(text);
    } catch (_) {
      // No TTS engine (tests, stripped-down devices) — stay silent.
    }
  }

  Future<void> stop() async {
    await _cloud?.stop();
    try {
      await _device.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _cloud?.dispose();
    try {
      await _device.stop();
    } catch (_) {}
  }
}
