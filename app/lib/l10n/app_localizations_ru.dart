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

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonSkip => 'Пропустить';

  @override
  String get commonCamera => 'Камера';

  @override
  String get commonGallery => 'Галерея';

  @override
  String get commonUnsupportedPhotoFormat =>
      'Не удалось распознать формат фото. Попробуйте JPEG, PNG или WebP.';

  @override
  String get commonUploadFailed => 'Не удалось загрузить документ.';

  @override
  String get documentVerificationTitle => 'Проверим данные автомобиля';

  @override
  String get documentVerificationBody =>
      'Если у вас есть техпаспорт или ПТС, загрузите его фотографию. Мы автоматически проверим, соответствуют ли введённые данные документу, и предупредим, если найдём расхождения.\n\nЭтот шаг необязателен — вы можете продолжить оформление договора без загрузки документа.';

  @override
  String get documentVerificationUploadButton => 'Загрузить техпаспорт';

  @override
  String get documentVerificationWorking => 'Сверяю данные с документом…';

  @override
  String get documentVerificationConflictTitle => 'Мы нашли отличие';

  @override
  String get documentVerificationYouEntered => 'Вы указали';

  @override
  String get documentVerificationInDocument => 'В документе';

  @override
  String get documentVerificationConflictRetryError =>
      'Не удалось сохранить значение. Попробуйте ещё раз.';

  @override
  String get documentVerificationUseDocumentValue =>
      'Использовать данные документа';

  @override
  String get documentVerificationKeepMine => 'Оставить мой вариант';

  @override
  String get documentVerificationCompareFailed =>
      'Не удалось проверить документ. Попробуйте ещё раз.';

  @override
  String get documentVerificationDoneTitle => 'Проверка завершена';

  @override
  String get documentVerificationDoneBody =>
      'Данные документа полностью совпадают с тем, что вы указали.';

  @override
  String documentVerificationConflictPosition(int position, int total) {
    return '$position из $total';
  }

  @override
  String questionnaireMyDocuments(int count) {
    return 'Мои документы ($count)';
  }

  @override
  String get questionnaireViewFixOrDelete =>
      'Посмотреть, исправить или удалить';

  @override
  String get questionnaireWhyNeeded => 'Зачем это нужно?';

  @override
  String get questionnaireGenerateFailed => 'Не удалось создать договор.';

  @override
  String get questionnaireReadyToGenerate => 'Договор готов к созданию';

  @override
  String get questionnaireOneMoment => 'Секунду…';

  @override
  String get questionnairePreparingNextStep => 'Готовлю следующий шаг…';

  @override
  String get questionnaireGenerateButton => 'Создать договор';

  @override
  String get questionnaireAttachDocument => 'Прикрепить документ';

  @override
  String get questionnaireSend => 'Отправить';

  @override
  String get questionnaireSpeakOrType => 'Напишите или скажите…';

  @override
  String get questionnaireSpeak => 'Озвучить';

  @override
  String get questionnaireRequired => 'Обязательно';

  @override
  String get questionnaireOptional => 'Необязательно';

  @override
  String get questionnaireConfirm => 'Подтвердить';

  @override
  String get questionnaireEditAnswer => 'Изменить';

  @override
  String get questionnaireSayAgain => 'Сказать заново';

  @override
  String get questionnaireUploadNotRequired => 'Можно не вводить вручную';

  @override
  String get questionnaireUploadDocument => 'Загрузить документ';

  @override
  String get questionnairePhotographDocument => 'Сфотографировать';

  @override
  String get questionnaireChooseFromGallery => 'Выбрать из галереи';

  @override
  String get questionnaireContinueWithoutDocument => 'Продолжить без документа';

  @override
  String get questionnaireLiveDocumentTitle =>
      'Договор создаётся в реальном времени';

  @override
  String get questionnairePreparingFirstStep => 'Готовлю первый шаг…';

  @override
  String get questionnairePreviousStep => 'Предыдущий шаг';

  @override
  String questionnaireAlreadyTold(int count) {
    return 'Вы уже сообщили: $count';
  }

  @override
  String get questionnaireListening => 'Слушаю…';

  @override
  String get questionnaireIUnderstood => 'Я понял:';

  @override
  String get questionnaireUploadNudgeBody =>
      'Если удобнее, загрузите фотографию документа — я сам заполню эти данные автоматически.';

  @override
  String get questionnaireUploadNudgeAlt =>
      'Или просто ответьте голосом или напишите вручную.';

  @override
  String questionnaireInviteMatchedFields(int count) {
    return 'Заполню около $count полей автоматически';
  }

  @override
  String get reviewHeroTitle => 'Договор почти готов';

  @override
  String reviewHeroFallback(String templateTitle) {
    return 'Проверьте детали — и я подготовлю «$templateTitle».';
  }

  @override
  String get reviewDocumentPendingNotice =>
      'Договор уже можно сформировать. Часть технических данных пока не заполнена — если позже загрузите техпаспорт, они подставятся автоматически.';

  @override
  String get reviewAutoFilledStat => 'заполнено\nавтоматически';

  @override
  String get reviewManualStatOne => 'вопрос вы\nответили сами';

  @override
  String get reviewManualStatMany => 'вопроса вы\nответили сами';

  @override
  String get reviewMissingTitle => 'Не хватает';

  @override
  String get reviewMissingSubtitle => 'Без этих данных договор будет неполным';

  @override
  String get reviewDisputedTitle => '⚠️ Нужно согласовать';

  @override
  String get reviewDisputedSubtitle =>
      'Есть спорное значение или предложение второй стороны — нажмите, чтобы указать итоговое';

  @override
  String get reviewAutoFilledTitle => '📄 Заполнено автоматически';

  @override
  String get reviewAutoFilledSubtitle => 'Из ваших документов';

  @override
  String get reviewCorrectedTitle => '✏️ Исправлено вами';

  @override
  String get reviewCorrectedSubtitle =>
      'Вы поправили то, что распознал документ';

  @override
  String get reviewManualTitle => '✍️ Вы указали сами';

  @override
  String get reviewSkippedTitle => '⏭️ Не требуется';

  @override
  String get reviewSkippedSubtitle =>
      'Подставляется системой или неактуально для вашего случая';

  @override
  String get reviewTapToFill => 'Нажмите, чтобы указать';

  @override
  String get reviewEditSaveFailed => 'Не удалось сохранить изменение';

  @override
  String get reviewStatusWaitingSecondParty => 'Ожидаем вторую сторону';

  @override
  String get reviewStatusWaitingObjectDocument =>
      'Нужен документ на объект сделки';

  @override
  String get reviewStatusMissingMandatoryTerms =>
      'Не хватает обязательных условий';

  @override
  String get reviewStatusWaitingPartyAgreement => 'Стороны согласуют условия';

  @override
  String get reviewStatusLegalReviewRequired =>
      'Требуется юридическая проверка';

  @override
  String get reviewRiskLowLabel => 'Низкий риск';

  @override
  String get reviewRiskLowMessage => 'Все ключевые сведения заполнены.';

  @override
  String get reviewRiskMediumLabel => 'Средний риск';

  @override
  String get reviewRiskMediumMessage =>
      'Отсутствуют некоторые сведения. Договор можно сформировать сейчас или сначала заполнить оставшееся для большей точности.';

  @override
  String get reviewRiskHighLabel => 'Высокий риск';

  @override
  String get reviewRiskHighMessage =>
      'Отсутствуют важные условия сделки. Мы можем сформировать договор сейчас, но это увеличивает юридический риск.';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileSettingsTooltip => 'Настройки';

  @override
  String profileLoadFailed(String error) {
    return 'Не удалось загрузить сохранённый профиль: $error';
  }

  @override
  String get profileSaved => 'Профиль сохранён';

  @override
  String get profileSaveFailed =>
      'Не удалось сохранить. Проверьте связь с сервером.';

  @override
  String get profileIntro =>
      'Эти данные подставляются в договор как данные вашей стороны — заполните их один раз, и в интервью они больше не спрашиваются.';

  @override
  String get profileFullNameLabel => 'Ф.И.О.';

  @override
  String get profileFullNameHint => 'Иванов Иван Иванович';

  @override
  String get profilePassportLabel => 'Серия и номер паспорта';

  @override
  String get profilePassportHint => 'AD 1234567';

  @override
  String get profileBirthDateLabel => 'Дата рождения';

  @override
  String get profileBirthDateHint => '01.01.1990';

  @override
  String get profileAddressLabel => 'Адрес';

  @override
  String get profileAddressHint => 'г. Ташкент, ул. Примерная, 1';

  @override
  String get homeGreetingNight => 'Доброй ночи';

  @override
  String get homeGreetingMorning => 'Доброе утро';

  @override
  String get homeGreetingDay => 'Добрый день';

  @override
  String get homeGreetingEvening => 'Добрый вечер';

  @override
  String get homeScanQrTooltip => 'Сканировать QR';

  @override
  String get homeProfileTooltip => 'Профиль';

  @override
  String get homeQuestion => 'О чём договариваемся?';

  @override
  String get homeSubtitle =>
      'Опишите словами или голосом — я подготовлю договор автоматически.';

  @override
  String get homeHint => 'Скажите или напишите, о чём хотите договориться…';

  @override
  String get homeListening => 'Слушаю…';

  @override
  String get homeHoldToTalk => 'Удерживайте, чтобы говорить';

  @override
  String get homeCreateAgreement => 'Создать договор';

  @override
  String get authTagline => 'Договоры с юридической силой';

  @override
  String get authMyIdTitle => 'Идентификация через MyID';

  @override
  String get authMyIdBody =>
      'Ваше имя, фамилия и паспортные данные будут подтверждены через MyID и автоматически подставлены в договор.';

  @override
  String get authContinueWithMyId => 'Продолжить с MyID';

  @override
  String get authVerifying => 'Проверяем данные…';

  @override
  String get authDemoModeNotice =>
      'Демо-режим — реальная интеграция появится позже';
}
