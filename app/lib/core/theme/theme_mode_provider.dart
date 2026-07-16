import 'package:flutter/material.dart';

import 'package:app/core/storage/local_storage.dart';

/// Persists the user's manually-chosen light/dark preference. Deliberately
/// never [ThemeMode.system]: the app defaults to light regardless of the
/// device's own setting, and only changes when the user explicitly picks
/// a theme in Settings.
class ThemeModeProvider extends ChangeNotifier {
  ThemeModeProvider(this._storage) {
    _load();
  }

  static const _storageKey = 'theme_mode';

  final LocalStorage _storage;
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  Future<void> _load() async {
    final saved = await _storage.read(_storageKey);
    if (saved == 'dark') {
      _mode = ThemeMode.dark;
      notifyListeners();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _storage.write(_storageKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}
