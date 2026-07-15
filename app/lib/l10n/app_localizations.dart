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

  /// No description provided for @commonSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get commonSave;

  /// No description provided for @commonSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get commonSkip;

  /// No description provided for @commonCamera.
  ///
  /// In ru, this message translates to:
  /// **'Камера'**
  String get commonCamera;

  /// No description provided for @commonGallery.
  ///
  /// In ru, this message translates to:
  /// **'Галерея'**
  String get commonGallery;

  /// No description provided for @commonUnsupportedPhotoFormat.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось распознать формат фото. Попробуйте JPEG, PNG или WebP.'**
  String get commonUnsupportedPhotoFormat;

  /// No description provided for @commonUploadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить документ.'**
  String get commonUploadFailed;

  /// No description provided for @documentVerificationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверим данные автомобиля'**
  String get documentVerificationTitle;

  /// No description provided for @documentVerificationBody.
  ///
  /// In ru, this message translates to:
  /// **'Если у вас есть техпаспорт или ПТС, загрузите его фотографию. Мы автоматически проверим, соответствуют ли введённые данные документу, и предупредим, если найдём расхождения.\n\nЭтот шаг необязателен — вы можете продолжить оформление договора без загрузки документа.'**
  String get documentVerificationBody;

  /// No description provided for @documentVerificationUploadButton.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить техпаспорт'**
  String get documentVerificationUploadButton;

  /// No description provided for @documentVerificationWorking.
  ///
  /// In ru, this message translates to:
  /// **'Сверяю данные с документом…'**
  String get documentVerificationWorking;

  /// No description provided for @documentVerificationConflictTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мы нашли отличие'**
  String get documentVerificationConflictTitle;

  /// No description provided for @documentVerificationYouEntered.
  ///
  /// In ru, this message translates to:
  /// **'Вы указали'**
  String get documentVerificationYouEntered;

  /// No description provided for @documentVerificationInDocument.
  ///
  /// In ru, this message translates to:
  /// **'В документе'**
  String get documentVerificationInDocument;

  /// No description provided for @documentVerificationConflictRetryError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить значение. Попробуйте ещё раз.'**
  String get documentVerificationConflictRetryError;

  /// No description provided for @documentVerificationUseDocumentValue.
  ///
  /// In ru, this message translates to:
  /// **'Использовать данные документа'**
  String get documentVerificationUseDocumentValue;

  /// No description provided for @documentVerificationKeepMine.
  ///
  /// In ru, this message translates to:
  /// **'Оставить мой вариант'**
  String get documentVerificationKeepMine;

  /// No description provided for @documentVerificationCompareFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось проверить документ. Попробуйте ещё раз.'**
  String get documentVerificationCompareFailed;

  /// No description provided for @documentVerificationDoneTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверка завершена'**
  String get documentVerificationDoneTitle;

  /// No description provided for @documentVerificationDoneBody.
  ///
  /// In ru, this message translates to:
  /// **'Данные документа полностью совпадают с тем, что вы указали.'**
  String get documentVerificationDoneBody;

  /// No description provided for @documentVerificationConflictPosition.
  ///
  /// In ru, this message translates to:
  /// **'{position} из {total}'**
  String documentVerificationConflictPosition(int position, int total);

  /// No description provided for @questionnaireMyDocuments.
  ///
  /// In ru, this message translates to:
  /// **'Мои документы ({count})'**
  String questionnaireMyDocuments(int count);

  /// No description provided for @questionnaireViewFixOrDelete.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть, исправить или удалить'**
  String get questionnaireViewFixOrDelete;

  /// No description provided for @questionnaireWhyNeeded.
  ///
  /// In ru, this message translates to:
  /// **'Зачем это нужно?'**
  String get questionnaireWhyNeeded;

  /// No description provided for @questionnaireGenerateFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать договор.'**
  String get questionnaireGenerateFailed;

  /// No description provided for @questionnaireReadyToGenerate.
  ///
  /// In ru, this message translates to:
  /// **'Договор готов к созданию'**
  String get questionnaireReadyToGenerate;

  /// No description provided for @questionnaireOneMoment.
  ///
  /// In ru, this message translates to:
  /// **'Секунду…'**
  String get questionnaireOneMoment;

  /// No description provided for @questionnairePreparingNextStep.
  ///
  /// In ru, this message translates to:
  /// **'Готовлю следующий шаг…'**
  String get questionnairePreparingNextStep;

  /// No description provided for @questionnaireGenerateButton.
  ///
  /// In ru, this message translates to:
  /// **'Создать договор'**
  String get questionnaireGenerateButton;

  /// No description provided for @questionnaireAttachDocument.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепить документ'**
  String get questionnaireAttachDocument;

  /// No description provided for @questionnaireSend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get questionnaireSend;

  /// No description provided for @questionnaireSpeakOrType.
  ///
  /// In ru, this message translates to:
  /// **'Напишите или скажите…'**
  String get questionnaireSpeakOrType;

  /// No description provided for @questionnaireSpeak.
  ///
  /// In ru, this message translates to:
  /// **'Озвучить'**
  String get questionnaireSpeak;

  /// No description provided for @questionnaireRequired.
  ///
  /// In ru, this message translates to:
  /// **'Обязательно'**
  String get questionnaireRequired;

  /// No description provided for @questionnaireOptional.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно'**
  String get questionnaireOptional;

  /// No description provided for @questionnaireConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get questionnaireConfirm;

  /// No description provided for @questionnaireEditAnswer.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get questionnaireEditAnswer;

  /// No description provided for @questionnaireSayAgain.
  ///
  /// In ru, this message translates to:
  /// **'Сказать заново'**
  String get questionnaireSayAgain;

  /// No description provided for @questionnaireUploadNotRequired.
  ///
  /// In ru, this message translates to:
  /// **'Можно не вводить вручную'**
  String get questionnaireUploadNotRequired;

  /// No description provided for @questionnaireUploadDocument.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить документ'**
  String get questionnaireUploadDocument;

  /// No description provided for @questionnairePhotographDocument.
  ///
  /// In ru, this message translates to:
  /// **'Сфотографировать'**
  String get questionnairePhotographDocument;

  /// No description provided for @questionnaireChooseFromGallery.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать из галереи'**
  String get questionnaireChooseFromGallery;

  /// No description provided for @questionnaireContinueWithoutDocument.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить без документа'**
  String get questionnaireContinueWithoutDocument;

  /// No description provided for @questionnaireLiveDocumentTitle.
  ///
  /// In ru, this message translates to:
  /// **'Договор создаётся в реальном времени'**
  String get questionnaireLiveDocumentTitle;

  /// No description provided for @questionnairePreparingFirstStep.
  ///
  /// In ru, this message translates to:
  /// **'Готовлю первый шаг…'**
  String get questionnairePreparingFirstStep;

  /// No description provided for @questionnairePreviousStep.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущий шаг'**
  String get questionnairePreviousStep;

  /// No description provided for @questionnaireAlreadyTold.
  ///
  /// In ru, this message translates to:
  /// **'Вы уже сообщили: {count}'**
  String questionnaireAlreadyTold(int count);

  /// No description provided for @questionnaireListening.
  ///
  /// In ru, this message translates to:
  /// **'Слушаю…'**
  String get questionnaireListening;

  /// No description provided for @questionnaireIUnderstood.
  ///
  /// In ru, this message translates to:
  /// **'Я понял:'**
  String get questionnaireIUnderstood;

  /// No description provided for @questionnaireUploadNudgeBody.
  ///
  /// In ru, this message translates to:
  /// **'Если удобнее, загрузите фотографию документа — я сам заполню эти данные автоматически.'**
  String get questionnaireUploadNudgeBody;

  /// No description provided for @questionnaireUploadNudgeAlt.
  ///
  /// In ru, this message translates to:
  /// **'Или просто ответьте голосом или напишите вручную.'**
  String get questionnaireUploadNudgeAlt;

  /// No description provided for @questionnaireInviteMatchedFields.
  ///
  /// In ru, this message translates to:
  /// **'Заполню около {count} полей автоматически'**
  String questionnaireInviteMatchedFields(int count);

  /// No description provided for @reviewHeroTitle.
  ///
  /// In ru, this message translates to:
  /// **'Договор почти готов'**
  String get reviewHeroTitle;

  /// No description provided for @reviewHeroFallback.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте детали — и я подготовлю «{templateTitle}».'**
  String reviewHeroFallback(String templateTitle);

  /// No description provided for @reviewDocumentPendingNotice.
  ///
  /// In ru, this message translates to:
  /// **'Договор уже можно сформировать. Часть технических данных пока не заполнена — если позже загрузите техпаспорт, они подставятся автоматически.'**
  String get reviewDocumentPendingNotice;

  /// No description provided for @reviewAutoFilledStat.
  ///
  /// In ru, this message translates to:
  /// **'заполнено\nавтоматически'**
  String get reviewAutoFilledStat;

  /// No description provided for @reviewManualStatOne.
  ///
  /// In ru, this message translates to:
  /// **'вопрос вы\nответили сами'**
  String get reviewManualStatOne;

  /// No description provided for @reviewManualStatMany.
  ///
  /// In ru, this message translates to:
  /// **'вопроса вы\nответили сами'**
  String get reviewManualStatMany;

  /// No description provided for @reviewMissingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Не хватает'**
  String get reviewMissingTitle;

  /// No description provided for @reviewMissingSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Без этих данных договор будет неполным'**
  String get reviewMissingSubtitle;

  /// No description provided for @reviewDisputedTitle.
  ///
  /// In ru, this message translates to:
  /// **'⚠️ Нужно согласовать'**
  String get reviewDisputedTitle;

  /// No description provided for @reviewDisputedSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Есть спорное значение или предложение второй стороны — нажмите, чтобы указать итоговое'**
  String get reviewDisputedSubtitle;

  /// No description provided for @reviewAutoFilledTitle.
  ///
  /// In ru, this message translates to:
  /// **'📄 Заполнено автоматически'**
  String get reviewAutoFilledTitle;

  /// No description provided for @reviewAutoFilledSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Из ваших документов'**
  String get reviewAutoFilledSubtitle;

  /// No description provided for @reviewCorrectedTitle.
  ///
  /// In ru, this message translates to:
  /// **'✏️ Исправлено вами'**
  String get reviewCorrectedTitle;

  /// No description provided for @reviewCorrectedSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Вы поправили то, что распознал документ'**
  String get reviewCorrectedSubtitle;

  /// No description provided for @reviewManualTitle.
  ///
  /// In ru, this message translates to:
  /// **'✍️ Вы указали сами'**
  String get reviewManualTitle;

  /// No description provided for @reviewSkippedTitle.
  ///
  /// In ru, this message translates to:
  /// **'⏭️ Не требуется'**
  String get reviewSkippedTitle;

  /// No description provided for @reviewSkippedSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Подставляется системой или неактуально для вашего случая'**
  String get reviewSkippedSubtitle;

  /// No description provided for @reviewTapToFill.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы указать'**
  String get reviewTapToFill;

  /// No description provided for @reviewEditSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить изменение'**
  String get reviewEditSaveFailed;

  /// No description provided for @reviewStatusWaitingSecondParty.
  ///
  /// In ru, this message translates to:
  /// **'Ожидаем вторую сторону'**
  String get reviewStatusWaitingSecondParty;

  /// No description provided for @reviewStatusWaitingObjectDocument.
  ///
  /// In ru, this message translates to:
  /// **'Нужен документ на объект сделки'**
  String get reviewStatusWaitingObjectDocument;

  /// No description provided for @reviewStatusMissingMandatoryTerms.
  ///
  /// In ru, this message translates to:
  /// **'Не хватает обязательных условий'**
  String get reviewStatusMissingMandatoryTerms;

  /// No description provided for @reviewStatusWaitingPartyAgreement.
  ///
  /// In ru, this message translates to:
  /// **'Стороны согласуют условия'**
  String get reviewStatusWaitingPartyAgreement;

  /// No description provided for @reviewStatusLegalReviewRequired.
  ///
  /// In ru, this message translates to:
  /// **'Требуется юридическая проверка'**
  String get reviewStatusLegalReviewRequired;

  /// No description provided for @reviewRiskLowLabel.
  ///
  /// In ru, this message translates to:
  /// **'Низкий риск'**
  String get reviewRiskLowLabel;

  /// No description provided for @reviewRiskLowMessage.
  ///
  /// In ru, this message translates to:
  /// **'Все ключевые сведения заполнены.'**
  String get reviewRiskLowMessage;

  /// No description provided for @reviewRiskMediumLabel.
  ///
  /// In ru, this message translates to:
  /// **'Средний риск'**
  String get reviewRiskMediumLabel;

  /// No description provided for @reviewRiskMediumMessage.
  ///
  /// In ru, this message translates to:
  /// **'Отсутствуют некоторые сведения. Договор можно сформировать сейчас или сначала заполнить оставшееся для большей точности.'**
  String get reviewRiskMediumMessage;

  /// No description provided for @reviewRiskHighLabel.
  ///
  /// In ru, this message translates to:
  /// **'Высокий риск'**
  String get reviewRiskHighLabel;

  /// No description provided for @reviewRiskHighMessage.
  ///
  /// In ru, this message translates to:
  /// **'Отсутствуют важные условия сделки. Мы можем сформировать договор сейчас, но это увеличивает юридический риск.'**
  String get reviewRiskHighMessage;

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

  /// No description provided for @profileSettingsTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get profileSettingsTooltip;

  /// No description provided for @profileLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить сохранённый профиль: {error}'**
  String profileLoadFailed(String error);

  /// No description provided for @profileSaved.
  ///
  /// In ru, this message translates to:
  /// **'Профиль сохранён'**
  String get profileSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить. Проверьте связь с сервером.'**
  String get profileSaveFailed;

  /// No description provided for @profileIntro.
  ///
  /// In ru, this message translates to:
  /// **'Эти данные подставляются в договор как данные вашей стороны — заполните их один раз, и в интервью они больше не спрашиваются.'**
  String get profileIntro;

  /// No description provided for @profileFullNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ф.И.О.'**
  String get profileFullNameLabel;

  /// No description provided for @profileFullNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Иванов Иван Иванович'**
  String get profileFullNameHint;

  /// No description provided for @profilePassportLabel.
  ///
  /// In ru, this message translates to:
  /// **'Серия и номер паспорта'**
  String get profilePassportLabel;

  /// No description provided for @profilePassportHint.
  ///
  /// In ru, this message translates to:
  /// **'AD 1234567'**
  String get profilePassportHint;

  /// No description provided for @profileBirthDateLabel.
  ///
  /// In ru, this message translates to:
  /// **'Дата рождения'**
  String get profileBirthDateLabel;

  /// No description provided for @profileBirthDateHint.
  ///
  /// In ru, this message translates to:
  /// **'01.01.1990'**
  String get profileBirthDateHint;

  /// No description provided for @profileAddressLabel.
  ///
  /// In ru, this message translates to:
  /// **'Адрес'**
  String get profileAddressLabel;

  /// No description provided for @profileAddressHint.
  ///
  /// In ru, this message translates to:
  /// **'г. Ташкент, ул. Примерная, 1'**
  String get profileAddressHint;

  /// No description provided for @homeGreetingNight.
  ///
  /// In ru, this message translates to:
  /// **'Доброй ночи'**
  String get homeGreetingNight;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In ru, this message translates to:
  /// **'Доброе утро'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingDay.
  ///
  /// In ru, this message translates to:
  /// **'Добрый день'**
  String get homeGreetingDay;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In ru, this message translates to:
  /// **'Добрый вечер'**
  String get homeGreetingEvening;

  /// No description provided for @homeScanQrTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать QR'**
  String get homeScanQrTooltip;

  /// No description provided for @homeProfileTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get homeProfileTooltip;

  /// No description provided for @homeQuestion.
  ///
  /// In ru, this message translates to:
  /// **'О чём договариваемся?'**
  String get homeQuestion;

  /// No description provided for @homeSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Опишите словами или голосом — я подготовлю договор автоматически.'**
  String get homeSubtitle;

  /// No description provided for @homeHint.
  ///
  /// In ru, this message translates to:
  /// **'Скажите или напишите, о чём хотите договориться…'**
  String get homeHint;

  /// No description provided for @homeListening.
  ///
  /// In ru, this message translates to:
  /// **'Слушаю…'**
  String get homeListening;

  /// No description provided for @homeHoldToTalk.
  ///
  /// In ru, this message translates to:
  /// **'Удерживайте, чтобы говорить'**
  String get homeHoldToTalk;

  /// No description provided for @homeCreateAgreement.
  ///
  /// In ru, this message translates to:
  /// **'Создать договор'**
  String get homeCreateAgreement;

  /// No description provided for @authTagline.
  ///
  /// In ru, this message translates to:
  /// **'Договоры с юридической силой'**
  String get authTagline;

  /// No description provided for @authMyIdTitle.
  ///
  /// In ru, this message translates to:
  /// **'Идентификация через MyID'**
  String get authMyIdTitle;

  /// No description provided for @authMyIdBody.
  ///
  /// In ru, this message translates to:
  /// **'Ваше имя, фамилия и паспортные данные будут подтверждены через MyID и автоматически подставлены в договор.'**
  String get authMyIdBody;

  /// No description provided for @authContinueWithMyId.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить с MyID'**
  String get authContinueWithMyId;

  /// No description provided for @authVerifying.
  ///
  /// In ru, this message translates to:
  /// **'Проверяем данные…'**
  String get authVerifying;

  /// No description provided for @authDemoModeNotice.
  ///
  /// In ru, this message translates to:
  /// **'Демо-режим — реальная интеграция появится позже'**
  String get authDemoModeNotice;

  /// No description provided for @commonPdf.
  ///
  /// In ru, this message translates to:
  /// **'PDF'**
  String get commonPdf;

  /// No description provided for @commonSend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get commonSend;

  /// No description provided for @commonBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get commonBack;

  /// No description provided for @commonDecline.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get commonDecline;

  /// No description provided for @commonHome.
  ///
  /// In ru, this message translates to:
  /// **'На главную'**
  String get commonHome;

  /// No description provided for @commonCopy.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get commonCopy;

  /// No description provided for @agreementCopied.
  ///
  /// In ru, this message translates to:
  /// **'Договор скопирован'**
  String get agreementCopied;

  /// No description provided for @agreementFirstPartyFallback.
  ///
  /// In ru, this message translates to:
  /// **'Первая сторона'**
  String get agreementFirstPartyFallback;

  /// No description provided for @agreementSignFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подписать договор.'**
  String get agreementSignFailed;

  /// No description provided for @agreementTitle.
  ///
  /// In ru, this message translates to:
  /// **'Договор'**
  String get agreementTitle;

  /// No description provided for @agreementNotCreatedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Договор ещё не создан'**
  String get agreementNotCreatedTitle;

  /// No description provided for @agreementNotCreatedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Пройдите интервью и создайте договор — он появится здесь.'**
  String get agreementNotCreatedMessage;

  /// No description provided for @agreementYouSignedWaitingSecond.
  ///
  /// In ru, this message translates to:
  /// **'Вы подписали договор.\nОжидание второй стороны.'**
  String get agreementYouSignedWaitingSecond;

  /// No description provided for @agreementSecondSignedWaitingYou.
  ///
  /// In ru, this message translates to:
  /// **'Вторая сторона уже подписала договор.\nПодпишите, чтобы завершить договор.'**
  String get agreementSecondSignedWaitingYou;

  /// No description provided for @agreementQrInstructions.
  ///
  /// In ru, this message translates to:
  /// **'Покажите этот QR-код второй стороне — она отсканирует его, пройдёт идентификацию через MyID и подпишет договор.'**
  String get agreementQrInstructions;

  /// No description provided for @agreementCreatedAt.
  ///
  /// In ru, this message translates to:
  /// **'Создан {time}'**
  String agreementCreatedAt(String time);

  /// No description provided for @agreementCopyTextTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать текст'**
  String get agreementCopyTextTooltip;

  /// No description provided for @agreementSharePdfTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться / PDF'**
  String get agreementSharePdfTooltip;

  /// No description provided for @agreementYouSigned.
  ///
  /// In ru, this message translates to:
  /// **'Вы подписали договор'**
  String get agreementYouSigned;

  /// No description provided for @agreementSignButton.
  ///
  /// In ru, this message translates to:
  /// **'Подписать договор'**
  String get agreementSignButton;

  /// No description provided for @agreementOpenAsSecondParty.
  ///
  /// In ru, this message translates to:
  /// **'Открыть как вторая сторона (на этом устройстве)'**
  String get agreementOpenAsSecondParty;

  /// No description provided for @agreementWaitingBothSignatures.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание подписи обеих сторон'**
  String get agreementWaitingBothSignatures;

  /// No description provided for @agreementWaitingSecondSignature.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание подписи второй стороны'**
  String get agreementWaitingSecondSignature;

  /// No description provided for @agreementBothSigned.
  ///
  /// In ru, this message translates to:
  /// **'Обе стороны подписали'**
  String get agreementBothSigned;

  /// No description provided for @agreementStepCreated.
  ///
  /// In ru, this message translates to:
  /// **'Создан'**
  String get agreementStepCreated;

  /// No description provided for @agreementStepCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Завершено'**
  String get agreementStepCompleted;

  /// No description provided for @agreementSignProposalSent.
  ///
  /// In ru, this message translates to:
  /// **'Предложение по «{label}» передано второй стороне.'**
  String agreementSignProposalSent(String label);

  /// No description provided for @agreementSignQuestionSent.
  ///
  /// In ru, this message translates to:
  /// **'Вопрос передан второй стороне.'**
  String get agreementSignQuestionSent;

  /// No description provided for @agreementSignDemoName.
  ///
  /// In ru, this message translates to:
  /// **'Иванов Иван Иванович'**
  String get agreementSignDemoName;

  /// No description provided for @agreementDocumentUnavailableTitle.
  ///
  /// In ru, this message translates to:
  /// **'Документ недоступен'**
  String get agreementDocumentUnavailableTitle;

  /// No description provided for @agreementNotFoundOrNotGenerated.
  ///
  /// In ru, this message translates to:
  /// **'Этот договор не найден или ещё не сформирован.'**
  String get agreementNotFoundOrNotGenerated;

  /// No description provided for @agreementSignTitle.
  ///
  /// In ru, this message translates to:
  /// **'Договор на подпись'**
  String get agreementSignTitle;

  /// No description provided for @agreementFullySigned.
  ///
  /// In ru, this message translates to:
  /// **'Договор полностью подписан.'**
  String get agreementFullySigned;

  /// No description provided for @agreementSecondPartySignedWaitingFirst.
  ///
  /// In ru, this message translates to:
  /// **'Вы подписали договор.\nОжидание первой стороны.'**
  String get agreementSecondPartySignedWaitingFirst;

  /// No description provided for @agreementFirstPartySignedWaitingSecond.
  ///
  /// In ru, this message translates to:
  /// **'Первая сторона уже подписала договор.\nПодпишите, чтобы завершить договор.'**
  String get agreementFirstPartySignedWaitingSecond;

  /// No description provided for @agreementMyIdNotice.
  ///
  /// In ru, this message translates to:
  /// **'Перед подписью — идентификация через MyID. Ваши имя и данные подставятся в договор автоматически.'**
  String get agreementMyIdNotice;

  /// No description provided for @agreementProposeChange.
  ///
  /// In ru, this message translates to:
  /// **'Изменить условие'**
  String get agreementProposeChange;

  /// No description provided for @agreementAskQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Задать вопрос'**
  String get agreementAskQuestion;

  /// No description provided for @agreementSignWithMyId.
  ///
  /// In ru, this message translates to:
  /// **'Пройти MyID и подписать'**
  String get agreementSignWithMyId;

  /// No description provided for @agreementNotFoundTitle.
  ///
  /// In ru, this message translates to:
  /// **'Договор не найден'**
  String get agreementNotFoundTitle;

  /// No description provided for @agreementNotFoundMessage.
  ///
  /// In ru, this message translates to:
  /// **'Похоже, вы попали сюда напрямую. Начните новую сделку с главного экрана.'**
  String get agreementNotFoundMessage;

  /// No description provided for @agreementSignedSuccessfully.
  ///
  /// In ru, this message translates to:
  /// **'Договор успешно подписан'**
  String get agreementSignedSuccessfully;

  /// No description provided for @agreementSignedBy.
  ///
  /// In ru, this message translates to:
  /// **'Подписал(а): {name}'**
  String agreementSignedBy(String name);

  /// No description provided for @agreementPdfExportFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать PDF. Попробуйте ещё раз.'**
  String get agreementPdfExportFailed;

  /// No description provided for @dealInviteFillProfileFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала заполните свои данные — они будут указаны в договоре.'**
  String get dealInviteFillProfileFirst;

  /// No description provided for @dealInviteRegenerateFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить договор вашими данными.'**
  String get dealInviteRegenerateFailed;

  /// No description provided for @dealInviteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение к сделке'**
  String get dealInviteTitle;

  /// No description provided for @dealInviteHeadline.
  ///
  /// In ru, this message translates to:
  /// **'Вас пригласили принять участие в сделке'**
  String get dealInviteHeadline;

  /// No description provided for @dealInviteTypeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Тип сделки'**
  String get dealInviteTypeLabel;

  /// No description provided for @dealInviteYourRoleLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ваша роль'**
  String get dealInviteYourRoleLabel;

  /// No description provided for @dealInviteInvitedByLabel.
  ///
  /// In ru, this message translates to:
  /// **'Пригласил'**
  String get dealInviteInvitedByLabel;

  /// No description provided for @dealInviteNotSpecified.
  ///
  /// In ru, this message translates to:
  /// **'Не указано'**
  String get dealInviteNotSpecified;

  /// No description provided for @dealInviteStatusLabel.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get dealInviteStatusLabel;

  /// No description provided for @dealInviteAccept.
  ///
  /// In ru, this message translates to:
  /// **'Принять'**
  String get dealInviteAccept;

  /// No description provided for @dealInviteDeclineDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить приглашение?'**
  String get dealInviteDeclineDialogTitle;

  /// No description provided for @dealInviteDeclineDialogBody.
  ///
  /// In ru, this message translates to:
  /// **'Вторая сторона увидит ваш ответ. Можете коротко объяснить почему — это необязательно.'**
  String get dealInviteDeclineDialogBody;

  /// No description provided for @dealInviteDeclineReasonHint.
  ///
  /// In ru, this message translates to:
  /// **'Причина (необязательно)…'**
  String get dealInviteDeclineReasonHint;

  /// No description provided for @dealInviteDeclined.
  ///
  /// In ru, this message translates to:
  /// **'Вы отклонили приглашение'**
  String get dealInviteDeclined;

  /// No description provided for @dealInviteStatusPending.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает подтверждения'**
  String get dealInviteStatusPending;

  /// No description provided for @dealInviteStatusOpened.
  ///
  /// In ru, this message translates to:
  /// **'Открыто'**
  String get dealInviteStatusOpened;

  /// No description provided for @dealInviteStatusAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Принято'**
  String get dealInviteStatusAccepted;

  /// No description provided for @dealInviteStatusDeclined.
  ///
  /// In ru, this message translates to:
  /// **'Отклонено'**
  String get dealInviteStatusDeclined;

  /// No description provided for @dealInviteStatusChangeRequested.
  ///
  /// In ru, this message translates to:
  /// **'Предложены изменения'**
  String get dealInviteStatusChangeRequested;

  /// No description provided for @dealInviteStatusClarificationRequested.
  ///
  /// In ru, this message translates to:
  /// **'Запрошено уточнение'**
  String get dealInviteStatusClarificationRequested;

  /// No description provided for @roleSeller.
  ///
  /// In ru, this message translates to:
  /// **'Продавец'**
  String get roleSeller;

  /// No description provided for @roleBuyer.
  ///
  /// In ru, this message translates to:
  /// **'Покупатель'**
  String get roleBuyer;

  /// No description provided for @roleLandlord.
  ///
  /// In ru, this message translates to:
  /// **'Арендодатель'**
  String get roleLandlord;

  /// No description provided for @roleTenant.
  ///
  /// In ru, this message translates to:
  /// **'Арендатор'**
  String get roleTenant;

  /// No description provided for @roleLender.
  ///
  /// In ru, this message translates to:
  /// **'Займодавец'**
  String get roleLender;

  /// No description provided for @roleBorrower.
  ///
  /// In ru, this message translates to:
  /// **'Заёмщик'**
  String get roleBorrower;

  /// No description provided for @roleEmployer.
  ///
  /// In ru, this message translates to:
  /// **'Работодатель'**
  String get roleEmployer;

  /// No description provided for @roleEmployee.
  ///
  /// In ru, this message translates to:
  /// **'Работник'**
  String get roleEmployee;

  /// No description provided for @roleCustomer.
  ///
  /// In ru, this message translates to:
  /// **'Заказчик'**
  String get roleCustomer;

  /// No description provided for @roleContractor.
  ///
  /// In ru, this message translates to:
  /// **'Исполнитель'**
  String get roleContractor;

  /// No description provided for @roleDonor.
  ///
  /// In ru, this message translates to:
  /// **'Даритель'**
  String get roleDonor;

  /// No description provided for @roleRecipient.
  ///
  /// In ru, this message translates to:
  /// **'Одаряемый'**
  String get roleRecipient;

  /// No description provided for @roleFirstParty.
  ///
  /// In ru, this message translates to:
  /// **'Первая сторона'**
  String get roleFirstParty;

  /// No description provided for @roleSecondParty.
  ///
  /// In ru, this message translates to:
  /// **'Вторая сторона'**
  String get roleSecondParty;

  /// No description provided for @roleParticipant.
  ///
  /// In ru, this message translates to:
  /// **'Участник сделки'**
  String get roleParticipant;

  /// No description provided for @negotiationWhatToChange.
  ///
  /// In ru, this message translates to:
  /// **'Что хотите изменить?'**
  String get negotiationWhatToChange;

  /// No description provided for @negotiationChooseTerm.
  ///
  /// In ru, this message translates to:
  /// **'Выберите условие договора — ваше предложение увидит вторая сторона.'**
  String get negotiationChooseTerm;

  /// No description provided for @negotiationNoEditableTerms.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет условий, которые можно изменить.'**
  String get negotiationNoEditableTerms;

  /// No description provided for @negotiationBackToList.
  ///
  /// In ru, this message translates to:
  /// **'К списку условий'**
  String get negotiationBackToList;

  /// No description provided for @negotiationCurrentValue.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас в договоре'**
  String get negotiationCurrentValue;

  /// No description provided for @negotiationYourProposalHint.
  ///
  /// In ru, this message translates to:
  /// **'Ваше предложение…'**
  String get negotiationYourProposalHint;

  /// No description provided for @negotiationReasonHint.
  ///
  /// In ru, this message translates to:
  /// **'Почему? (необязательно)'**
  String get negotiationReasonHint;

  /// No description provided for @negotiationSendProposal.
  ///
  /// In ru, this message translates to:
  /// **'Отправить предложение'**
  String get negotiationSendProposal;

  /// No description provided for @negotiationAskQuestionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Задать вопрос'**
  String get negotiationAskQuestionTitle;

  /// No description provided for @negotiationAskQuestionBody.
  ///
  /// In ru, this message translates to:
  /// **'Спросите то, что хотите уточнить перед подписанием — вопрос увидит вторая сторона.'**
  String get negotiationAskQuestionBody;

  /// No description provided for @negotiationQuestionHint.
  ///
  /// In ru, this message translates to:
  /// **'Ваш вопрос…'**
  String get negotiationQuestionHint;
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
