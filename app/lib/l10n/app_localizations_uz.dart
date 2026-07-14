// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get settingsTitle => 'Созламалар';

  @override
  String get settingsLanguageTitle => 'Интерфейс тили';

  @override
  String get settingsLanguagePickerTitle => 'Тилни танланг';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageUzbek => 'Ўзбекча';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsThemeTitle => 'Мавзу';

  @override
  String get settingsThemeSubtitle => 'Ёруғ';

  @override
  String get settingsVoiceTitle => 'Саволларни овозли ўқиш';

  @override
  String get settingsVoiceSubtitleOn =>
      'Ассистент саволларни овоз чиқариб ўқийди';

  @override
  String get settingsVoiceSubtitleOff => 'Ўчирилган';

  @override
  String get settingsAboutTitle => 'Дастур ҳақида';

  @override
  String settingsAboutSubtitle(String appName) {
    return '$appName · демо-версия';
  }

  @override
  String get settingsAboutVersion => 'Демо-версия';

  @override
  String get settingsDeleteProfile => 'Профилни ўчириш';

  @override
  String get deleteProfileDialogTitle => 'Профилни ўчирасизми?';

  @override
  String get deleteProfileDialogContent =>
      'Сақланган маълумотларингиз (Ф.И.Ш., паспорт, манзил) серверда ўчириб ташланади.';

  @override
  String get commonCancel => 'Бекор қилиш';

  @override
  String get commonDelete => 'Ўчириш';

  @override
  String get commonUnderstood => 'Тушунарли';
}
