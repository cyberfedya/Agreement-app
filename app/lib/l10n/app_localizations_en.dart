// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageTitle => 'Interface language';

  @override
  String get settingsLanguagePickerTitle => 'Choose a language';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageUzbek => 'Ўзбекча';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsThemeTitle => 'Theme';

  @override
  String get settingsThemeSubtitle => 'Light';

  @override
  String get settingsVoiceTitle => 'Read questions aloud';

  @override
  String get settingsVoiceSubtitleOn =>
      'The assistant reads questions out loud';

  @override
  String get settingsVoiceSubtitleOff => 'Off';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String settingsAboutSubtitle(String appName) {
    return '$appName · demo version';
  }

  @override
  String get settingsAboutVersion => 'Demo version';

  @override
  String get settingsDeleteProfile => 'Delete profile';

  @override
  String get deleteProfileDialogTitle => 'Delete profile?';

  @override
  String get deleteProfileDialogContent =>
      'Your saved data (full name, passport, address) will be deleted from the server.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonUnderstood => 'Got it';
}
