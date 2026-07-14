import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Язык интерфейса'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguagePickerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите язык'**
  String get settingsLanguagePickerTitle;

  /// No description provided for @languageRussian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageUzbek.
  ///
  /// In ru, this message translates to:
  /// **'Ўзбекча'**
  String get languageUzbek;

  /// No description provided for @languageEnglish.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get settingsThemeSubtitle;

  /// No description provided for @settingsVoiceTitle.
  ///
  /// In ru, this message translates to:
  /// **'Озвучка вопросов'**
  String get settingsVoiceTitle;

  /// No description provided for @settingsVoiceSubtitleOn.
  ///
  /// In ru, this message translates to:
  /// **'Ассистент читает вопросы вслух'**
  String get settingsVoiceSubtitleOn;

  /// No description provided for @settingsVoiceSubtitleOff.
  ///
  /// In ru, this message translates to:
  /// **'Выключена'**
  String get settingsVoiceSubtitleOff;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In ru, this message translates to:
  /// **'О программе'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'{appName} · демо-версия'**
  String settingsAboutSubtitle(String appName);

  /// No description provided for @settingsAboutVersion.
  ///
  /// In ru, this message translates to:
  /// **'Демо-версия'**
  String get settingsAboutVersion;

  /// No description provided for @settingsDeleteProfile.
  ///
  /// In ru, this message translates to:
  /// **'Удалить профиль'**
  String get settingsDeleteProfile;

  /// No description provided for @deleteProfileDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить профиль?'**
  String get deleteProfileDialogTitle;

  /// No description provided for @deleteProfileDialogContent.
  ///
  /// In ru, this message translates to:
  /// **'Ваши сохранённые данные (Ф.И.О., паспорт, адрес) будут удалены с сервера.'**
  String get deleteProfileDialogContent;

  /// No description provided for @commonCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get commonDelete;

  /// No description provided for @commonUnderstood.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get commonUnderstood;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
