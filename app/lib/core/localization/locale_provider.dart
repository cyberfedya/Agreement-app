import 'package:flutter/material.dart';

import 'package:app/core/storage/local_storage.dart';

/// Persists the user's chosen interface language and exposes it as a
/// [Locale] for `MaterialApp`. Also the single source of truth for the
/// `lang` code sent to the backend's interview endpoints, so switching the
/// interface language switches the interview language too.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider(this._storage) {
    _load();
  }

  static const _storageKey = 'locale';
  static const supportedLocales = [Locale('ru'), Locale('uz'), Locale('en')];

  final LocalStorage _storage;
  Locale _locale = const Locale('ru');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  Future<void> _load() async {
    final saved = await _storage.read(_storageKey);
    if (saved != null && supportedLocales.any((l) => l.languageCode == saved)) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    await _storage.write(_storageKey, locale.languageCode);
  }
}
