import 'package:flutter/foundation.dart';
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
      debugPrint('TtsService: cloud TTS unavailable/failed, falling back to on-device engine');
    } catch (e) {
      debugPrint('TtsService: cloud TTS threw, falling back to on-device engine: $e');
    }

    try {
      await _device.stop();
      final locale = switch (lang) { 'ru' => 'ru-RU', 'uz' => 'uz-UZ', _ => 'en-US' };
      final supported = await _device.isLanguageAvailable(locale);
      // Many Android devices never downloaded the Russian/Uzbek voice pack —
      // silently falling back to whatever locale IS installed beats staying
      // mute, even if the accent ends up wrong.
      if (supported != true) {
        debugPrint('TtsService: locale $locale not available on this device, using engine default');
      } else {
        await _device.setLanguage(locale);
      }
      // No male on-device voice is guaranteed; a lower pitch approximates one.
      await _device.setPitch(0.8);
      final result = await _device.speak(text);
      debugPrint('TtsService: on-device speak() result=$result');
    } catch (e) {
      debugPrint('TtsService: on-device TTS threw: $e');
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
