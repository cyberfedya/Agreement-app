// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguageTitle => 'Язык интерфейса';

  @override
  String get settingsLanguagePickerTitle => 'Выберите язык';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageUzbek => 'Ўзбекча';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsThemeTitle => 'Тема';

  @override
  String get settingsThemeSubtitle => 'Светлая';

  @override
  String get settingsVoiceTitle => 'Озвучка вопросов';

  @override
  String get settingsVoiceSubtitleOn => 'Ассистент читает вопросы вслух';

  @override
  String get settingsVoiceSubtitleOff => 'Выключена';

  @override
  String get settingsAboutTitle => 'О программе';

  @override
  String settingsAboutSubtitle(String appName) {
    return '$appName · демо-версия';
  }

  @override
  String get settingsAboutVersion => 'Демо-версия';

  @override
  String get settingsDeleteProfile => 'Удалить профиль';

  @override
  String get deleteProfileDialogTitle => 'Удалить профиль?';

  @override
  String get deleteProfileDialogContent =>
      'Ваши сохранённые данные (Ф.И.О., паспорт, адрес) будут удалены с сервера.';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonUnderstood => 'Понятно';
}
