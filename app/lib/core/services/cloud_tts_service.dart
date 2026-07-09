import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Google Cloud Text-to-Speech client.
///
/// Synthesizes speech with premium Chirp3-HD voices (e.g. the male
/// `ru-RU-Chirp3-HD-Charon`) — these only exist in the Cloud API, NOT in the
/// on-device flutter_tts engine. Returns MP3 audio that is played via
/// just_audio.
///
/// The API key is provided at build time:
///   `--dart-define=GOOGLE_TTS_KEY=your_key`
/// If no key is set, [isAvailable] is false and callers should fall back to
/// on-device TTS.
class CloudTtsService {
  CloudTtsService();

  static const String _apiKey =
      String.fromEnvironment('GOOGLE_TTS_KEY', defaultValue: '');
  static const String _endpoint =
      'https://texttospeech.googleapis.com/v1/text:synthesize';

  final Dio _dio = Dio();
  final AudioPlayer _player = AudioPlayer();
  int _counter = 0;

  bool get isAvailable => _apiKey.isNotEmpty;

  /// Synthesizes [text] with the Chirp3-HD male voice for [lang] and starts
  /// playback. Returns true on success; false if unavailable/unsupported/failed
  /// so the caller can fall back to on-device TTS.
  Future<bool> speakForLanguage(String text, String lang) async {
    if (!isAvailable || text.trim().isEmpty) return false;
    final voice = _voiceFor(lang);
    if (voice == null) return false;

    try {
      final res = await _dio.post(
        _endpoint,
        queryParameters: {'key': _apiKey},
        options: Options(contentType: 'application/json'),
        data: {
          'input': {'text': text},
          'voice': {
            'languageCode': voice.languageCode,
            'name': voice.voiceName,
          },
          'audioConfig': {'audioEncoding': 'MP3'},
        },
      );

      final b64 = res.data?['audioContent'] as String?;
      if (b64 == null || b64.isEmpty) return false;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cloud_tts_${_counter++}.mp3');
      await file.writeAsBytes(base64Decode(b64), flush: true);

      await _player.stop();
      await _player.setFilePath(file.path);
      _player.play(); // fire-and-forget; completes when audio finishes
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  /// Chirp3-HD male voice (Charon) — Russian only. Other languages return null
  /// → caller routes them elsewhere (Uzbek → Muxlisa, English → on-device).
  ({String languageCode, String voiceName})? _voiceFor(String lang) {
    return switch (lang) {
      'ru' => (languageCode: 'ru-RU', voiceName: 'ru-RU-Chirp3-HD-Charon'),
      _ => null,
    };
  }
}
