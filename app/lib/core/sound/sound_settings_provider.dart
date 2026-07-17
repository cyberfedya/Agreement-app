import 'package:flutter/foundation.dart';

import 'package:app/core/storage/local_storage.dart';

/// How much of the interface sound layer plays. `minimal` (the default)
/// covers only the "important event" sounds (document verified, deal
/// created, party joined, error, attention); `extended` adds the
/// fine-grained per-field/per-stage micro-sounds on top.
enum SoundLevel { off, minimal, extended }

/// Persists the user's interface-sound preference, the same load/persist
/// shape as `ThemeModeProvider`.
class SoundSettingsProvider extends ChangeNotifier {
  SoundSettingsProvider(this._storage) {
    _load();
  }

  static const _storageKey = 'sound_level';

  final LocalStorage _storage;
  SoundLevel _level = SoundLevel.minimal;

  SoundLevel get level => _level;

  Future<void> _load() async {
    final saved = await _storage.read(_storageKey);
    final parsed = SoundLevel.values.where((l) => l.name == saved).firstOrNull;
    if (parsed != null) {
      _level = parsed;
      notifyListeners();
    }
  }

  Future<void> setLevel(SoundLevel level) async {
    if (level == _level) return;
    _level = level;
    notifyListeners();
    await _storage.write(_storageKey, level.name);
  }
}
