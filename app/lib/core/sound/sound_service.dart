import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:app/core/sound/app_sound.dart';
import 'package:app/core/sound/sound_settings_provider.dart';

/// Plays short interface sounds, gated by [SoundSettingsProvider]. One
/// [AudioPlayer] per [AppSound] is preloaded at construction so the first
/// play of each sound has no decode latency - short UI sounds need to feel
/// instant.
class SoundService {
  SoundService(this._settings) {
    for (final sound in AppSound.values) {
      final player = AudioPlayer();
      _players[sound] = player;
      unawaited(player.setAsset(sound.assetPath).catchError((Object error, StackTrace stack) {
        debugPrint('SoundService: failed to preload ${sound.assetPath}: $error');
        return null;
      }));
    }
  }

  final SoundSettingsProvider _settings;
  final Map<AppSound, AudioPlayer> _players = {};

  Future<void> play(AppSound sound) async {
    final level = _settings.level;
    if (level == SoundLevel.off || level.index < sound.minimumLevel.index) return;

    final player = _players[sound];
    if (player == null) return;
    try {
      await player.seek(Duration.zero);
      await player.play();
    } catch (error) {
      debugPrint('SoundService: failed to play ${sound.assetPath}: $error');
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
  }
}
