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
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

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
  String get questionnaireContinue => 'Продолжить';

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
  String get profileFullNameHint => 'Фамилия Имя Отчество';

  @override
  String get profilePassportLabel => 'Серия и номер паспорта';

  @override
  String get profilePassportHint => 'Серия и номер';

  @override
  String get profilePassportInvalid =>
      'Формат: две буквы и семь цифр, например AB1234567.';

  @override
  String get profileBirthDateLabel => 'Дата рождения';

  @override
  String get profileBirthDateHint => 'ДД.ММ.ГГГГ';

  @override
  String get profileAddressLabel => 'Адрес';

  @override
  String get profileAddressHint => 'Город, улица, дом';

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

  @override
  String get commonPdf => 'PDF';

  @override
  String get commonSend => 'Отправить';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonDecline => 'Отклонить';

  @override
  String get commonHome => 'На главную';

  @override
  String get commonCopy => 'Копировать';

  @override
  String get agreementCopied => 'Договор скопирован';

  @override
  String get agreementFirstPartyFallback => 'Первая сторона';

  @override
  String get agreementSignFailed => 'Не удалось подписать договор.';

  @override
  String get agreementTitle => 'Договор';

  @override
  String get agreementNotCreatedTitle => 'Договор ещё не создан';

  @override
  String get agreementNotCreatedMessage =>
      'Пройдите интервью и создайте договор — он появится здесь.';

  @override
  String get agreementYouSignedWaitingSecond =>
      'Вы подписали договор.\nОжидание второй стороны.';

  @override
  String get agreementSecondSignedWaitingYou =>
      'Вторая сторона уже подписала договор.\nПодпишите, чтобы завершить договор.';

  @override
  String get agreementQrInstructions =>
      'Покажите этот QR-код второй стороне — она отсканирует его, пройдёт идентификацию через MyID и подпишет договор.';

  @override
  String agreementCreatedAt(String time) {
    return 'Создан $time';
  }

  @override
  String get agreementCopyTextTooltip => 'Скопировать текст';

  @override
  String get agreementSharePdfTooltip => 'Поделиться / PDF';

  @override
  String get agreementYouSigned => 'Вы подписали договор';

  @override
  String get agreementSignButton => 'Подписать договор';

  @override
  String get agreementOpenAsSecondParty =>
      'Открыть как вторая сторона (на этом устройстве)';

  @override
  String get agreementWaitingBothSignatures => 'Ожидание подписи обеих сторон';

  @override
  String get agreementWaitingSecondSignature =>
      'Ожидание подписи второй стороны';

  @override
  String get agreementBothSigned => 'Обе стороны подписали';

  @override
  String get agreementStepCreated => 'Создан';

  @override
  String get agreementStepCompleted => 'Завершено';

  @override
  String agreementSignProposalSent(String label) {
    return 'Предложение по «$label» передано второй стороне.';
  }

  @override
  String get agreementSignQuestionSent => 'Вопрос передан второй стороне.';

  @override
  String get agreementSignDemoName => 'Иванов Иван Иванович';

  @override
  String get agreementDocumentUnavailableTitle => 'Документ недоступен';

  @override
  String get agreementNotFoundOrNotGenerated =>
      'Этот договор не найден или ещё не сформирован.';

  @override
  String get agreementSignTitle => 'Договор на подпись';

  @override
  String get agreementFullySigned => 'Договор полностью подписан.';

  @override
  String get agreementSecondPartySignedWaitingFirst =>
      'Вы подписали договор.\nОжидание первой стороны.';

  @override
  String get agreementFirstPartySignedWaitingSecond =>
      'Первая сторона уже подписала договор.\nПодпишите, чтобы завершить договор.';

  @override
  String get agreementMyIdNotice =>
      'Перед подписью — идентификация через MyID. Ваши имя и данные подставятся в договор автоматически.';

  @override
  String get agreementProposeChange => 'Изменить условие';

  @override
  String get agreementAskQuestion => 'Задать вопрос';

  @override
  String get agreementSignWithMyId => 'Пройти MyID и подписать';

  @override
  String get agreementNotFoundTitle => 'Договор не найден';

  @override
  String get agreementNotFoundMessage =>
      'Похоже, вы попали сюда напрямую. Начните новую сделку с главного экрана.';

  @override
  String get agreementSignedSuccessfully => 'Договор успешно подписан';

  @override
  String agreementSignedBy(String name) {
    return 'Подписал(а): $name';
  }

  @override
  String get agreementPdfExportFailed =>
      'Не удалось создать PDF. Попробуйте ещё раз.';

  @override
  String get dealInviteFillProfileFirst =>
      'Сначала заполните свои данные — они будут указаны в договоре.';

  @override
  String get dealInviteRegenerateFailed =>
      'Не удалось обновить договор вашими данными.';

  @override
  String get dealInviteTitle => 'Приглашение к сделке';

  @override
  String get dealInviteHeadline => 'Вас пригласили принять участие в сделке';

  @override
  String get dealInviteTypeLabel => 'Тип сделки';

  @override
  String get dealInviteYourRoleLabel => 'Ваша роль';

  @override
  String get dealInviteInvitedByLabel => 'Пригласил';

  @override
  String get dealInviteNotSpecified => 'Не указано';

  @override
  String get dealInviteStatusLabel => 'Статус';

  @override
  String get dealInviteAccept => 'Принять';

  @override
  String get dealInviteDeclineDialogTitle => 'Отклонить приглашение?';

  @override
  String get dealInviteDeclineDialogBody =>
      'Вторая сторона увидит ваш ответ. Можете коротко объяснить почему — это необязательно.';

  @override
  String get dealInviteDeclineReasonHint => 'Причина (необязательно)…';

  @override
  String get dealInviteDeclined => 'Вы отклонили приглашение';

  @override
  String get dealInviteStatusPending => 'Ожидает подтверждения';

  @override
  String get dealInviteStatusOpened => 'Открыто';

  @override
  String get dealInviteStatusAccepted => 'Принято';

  @override
  String get dealInviteStatusDeclined => 'Отклонено';

  @override
  String get dealInviteStatusChangeRequested => 'Предложены изменения';

  @override
  String get dealInviteStatusClarificationRequested => 'Запрошено уточнение';

  @override
  String get roleSeller => 'Продавец';

  @override
  String get roleBuyer => 'Покупатель';

  @override
  String get roleLandlord => 'Арендодатель';

  @override
  String get roleTenant => 'Арендатор';

  @override
  String get roleLender => 'Займодавец';

  @override
  String get roleBorrower => 'Заёмщик';

  @override
  String get roleEmployer => 'Работодатель';

  @override
  String get roleEmployee => 'Работник';

  @override
  String get roleCustomer => 'Заказчик';

  @override
  String get roleContractor => 'Исполнитель';

  @override
  String get roleDonor => 'Даритель';

  @override
  String get roleRecipient => 'Одаряемый';

  @override
  String get roleFirstParty => 'Первая сторона';

  @override
  String get roleSecondParty => 'Вторая сторона';

  @override
  String get roleParticipant => 'Участник сделки';

  @override
  String get negotiationWhatToChange => 'Что хотите изменить?';

  @override
  String get negotiationChooseTerm =>
      'Выберите условие договора — ваше предложение увидит вторая сторона.';

  @override
  String get negotiationNoEditableTerms =>
      'Пока нет условий, которые можно изменить.';

  @override
  String get negotiationBackToList => 'К списку условий';

  @override
  String get negotiationCurrentValue => 'Сейчас в договоре';

  @override
  String get negotiationYourProposalHint => 'Ваше предложение…';

  @override
  String get negotiationReasonHint => 'Почему? (необязательно)';

  @override
  String get negotiationSendProposal => 'Отправить предложение';

  @override
  String get negotiationAskQuestionTitle => 'Задать вопрос';

  @override
  String get negotiationAskQuestionBody =>
      'Спросите то, что хотите уточнить перед подписанием — вопрос увидит вторая сторона.';

  @override
  String get negotiationQuestionHint => 'Ваш вопрос…';

  @override
  String get documentsUploadedTitle => 'Загруженные документы';

  @override
  String get documentsEmptyState =>
      'Документов пока нет. Прикрепите фото через скрепку — я заполню данные автоматически.';

  @override
  String get documentsDeleteDialogTitle => 'Удалить документ?';

  @override
  String documentsDeleteDialogBody(String fileName) {
    return '«$fileName» и все распознанные из него данные будут удалены из сделки.';
  }

  @override
  String get documentsDeleteTooltip => 'Удалить документ';

  @override
  String get documentsRecognitionFailed => 'Не удалось распознать документ.';

  @override
  String get templatesTitle => 'Шаблоны договоров';

  @override
  String get templatesNothingFoundTitle => 'Ничего не найдено';

  @override
  String get templatesNothingFoundMessage =>
      'Попробуйте другой запрос или категорию.';

  @override
  String get templatesResetFilters => 'Сбросить фильтры';

  @override
  String get templatesAll => 'Все';

  @override
  String get templateDetailTitle => 'Шаблон договора';

  @override
  String get templateDetailNotFoundTitle => 'Шаблон не найден';

  @override
  String get templateDetailNotFoundMessage =>
      'Этот шаблон договора недоступен.';

  @override
  String get templateDetailCategoryLabel => 'Категория';

  @override
  String get templateDetailQuestionsLabel => 'Вопросов';

  @override
  String get templateDetailTimeLabel => 'Время';

  @override
  String templateDetailTimeValue(int minutes) {
    return '~$minutes мин';
  }

  @override
  String get templateDetailAboutTitle => 'Об этом договоре';

  @override
  String get templateDetailSourceTitle => 'Источник';

  @override
  String get templateDetailContinue => 'Продолжить';

  @override
  String get qrTitle => 'Сканировать QR-код';

  @override
  String get qrNotAgreementCode => 'Это не QR-код договора EasyAgree';

  @override
  String get qrHint => 'Наведите камеру на QR-код договора';

  @override
  String get qrCameraPermissionNeeded =>
      'Нужен доступ к камере, чтобы сканировать QR-код договора.';

  @override
  String get qrAllowAccess => 'Разрешить доступ';

  @override
  String get onboardingSlide1Title =>
      'Просто расскажите,\nо чём договариваетесь';

  @override
  String get onboardingSlide1Body =>
      'Своими словами или голосом — ИИ сам поймёт, какой договор нужен, и подготовит его.';

  @override
  String get onboardingSlide2Title =>
      'Сфотографируйте документ —\nостальное заполнится само';

  @override
  String get onboardingSlide2Body =>
      'Техпаспорт, кадастровые документы, реквизиты: ИИ распознает их и заполнит договор автоматически.';

  @override
  String get onboardingSlide3Title => 'Вторая сторона подписывает\nпо QR-коду';

  @override
  String get onboardingSlide3Body =>
      'Покажите код — партнёр откроет договор у себя, предложит правки или сразу подпишет.';

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get appEmptyStateDefaultTitle => 'Здесь пока пусто';

  @override
  String get appErrorTitle => 'Что-то пошло не так';

  @override
  String get appErrorRetry => 'Повторить';

  @override
  String get searchHint => 'Поиск договоров…';

  @override
  String get searchClearTooltip => 'Очистить';

  @override
  String progressStepOf(int current, int total) {
    return '$current из $total';
  }

  @override
  String get routeNotFoundTitle => 'Страница не найдена';

  @override
  String routeNotFoundMessage(String routeName) {
    return 'Экран \"$routeName\" не существует в этой сборке.';
  }

  @override
  String get categoryVehicle => 'Транспорт';

  @override
  String get categoryRealEstate => 'Недвижимость';

  @override
  String get categoryRent => 'Аренда';

  @override
  String get categoryEmployment => 'Работа';

  @override
  String get categoryLoan => 'Займы';

  @override
  String get categoryService => 'Услуги';

  @override
  String get categoryGift => 'Дарение';

  @override
  String get categoryFamily => 'Семья';

  @override
  String get categoryConstruction => 'Строительство';

  @override
  String get categoryPowerOfAttorney => 'Доверенности';

  @override
  String get categoryBusiness => 'Бизнес';

  @override
  String get categorySale => 'Купля-продажа';

  @override
  String get aiProcessingStep1 => 'Анализируем информацию…';

  @override
  String get aiProcessingStep2 => 'Формируем структуру договора…';

  @override
  String get aiProcessingStep3 => 'Определяем необходимые условия…';

  @override
  String get aiProcessingStep4 => 'Почти готово…';

  @override
  String get aiProcessingServerError => 'Не удалось связаться с сервером.';

  @override
  String get aiProcessingNoMatchTitle => 'Не удалось определить тип договора';

  @override
  String get aiProcessingNoMatchBody =>
      'Опишите подробнее, о чём хотите договориться — например, «продаю автомобиль» или «сдаю квартиру в аренду».';

  @override
  String get aiProcessingEditRequest => 'Изменить запрос';

  @override
  String extractionFilledSummary(int count, String plural, String remaining) {
    return 'Заполнил автоматически $count $plural — вам не придётся вводить их вручную. $remaining';
  }

  @override
  String get extractionPluralFieldOne => 'поле';

  @override
  String get extractionPluralFieldFew => 'поля';

  @override
  String get extractionPluralFieldMany => 'полей';

  @override
  String get extractionRemainingUnknown =>
      'Осталось уточнить лишь пару деталей.';

  @override
  String get extractionRemainingNone =>
      'Вопросов не осталось — договор почти готов.';

  @override
  String get extractionRemainingOne => 'Осталась всего одна деталь.';

  @override
  String extractionRemainingFew(int n) {
    return 'Осталось всего $n детали.';
  }

  @override
  String extractionRemainingMany(int n) {
    return 'Осталось $n деталей.';
  }

  @override
  String extractionAndMore(int count) {
    return 'и ещё $count…';
  }

  @override
  String get extractionContinue => 'Продолжить';

  @override
  String get profileHistoryEntry => 'История договоров';

  @override
  String get historyTitle => 'История договоров';

  @override
  String get historySearchHint => 'Поиск по названию или стороне';

  @override
  String get historyFilterAll => 'Все';

  @override
  String get historyFilterDraft => 'Черновики';

  @override
  String get historyFilterSigned => 'Подписанные';

  @override
  String get historyFilterWaiting => 'Ожидают подписи';

  @override
  String get historyFilterCancelled => 'Отменённые';

  @override
  String get historyEmptyTitle => 'У вас пока нет договоров';

  @override
  String get historyEmptyMessage =>
      'Создайте первый договор, и он появится здесь.';

  @override
  String get historyCreateDeal => 'Создать договор';

  @override
  String get historyNothingFoundMessage =>
      'По этому фильтру или запросу ничего не найдено.';

  @override
  String get historyStatusDraft => 'Черновик';

  @override
  String get historyStatusWaitingSecondParty => 'Ожидает вторую сторону';

  @override
  String get historyStatusWaitingYourSignature => 'Ожидает вашей подписи';

  @override
  String get historyStatusSigned => 'Подписан';

  @override
  String get historyStatusCancelled => 'Отменён';

  @override
  String get historyDetailCreatedLabel => 'Создан';

  @override
  String get historyDetailUpdatedLabel => 'Обновлён';

  @override
  String get historyDetailSecondPartyLabel => 'Вторая сторона';

  @override
  String get historyDetailStatusLabel => 'Статус';

  @override
  String get historyDetailContinue => 'Продолжить оформление';

  @override
  String get historyDetailOpenDocument => 'Открыть договор';

  @override
  String get historyDetailCancelDeal => 'Отменить сделку';

  @override
  String get historyDetailCancelConfirmTitle => 'Отменить сделку?';

  @override
  String get historyDetailCancelConfirmBody =>
      'Это действие нельзя отменить. Договор будет помечен как отменённый.';

  @override
  String get historyDetailCancelConfirmButton => 'Отменить сделку';

  @override
  String get historyDetailCancelFailed => 'Не удалось отменить сделку.';

  @override
  String get historyDetailCancelledNotice => 'Эта сделка отменена.';

  @override
  String get explanationDeposit =>
      'Если будет предоплата, мы добавим это условие в договор. Тогда обе стороны будут понимать, какую сумму и когда нужно оплатить.';

  @override
  String get explanationPaymentMethod =>
      'Нам нужно указать способ оплаты. Это поможет точно описать порядок расчёта в договоре.';

  @override
  String get explanationBankDetails =>
      'Мы спрашиваем реквизиты, чтобы деньги ушли на правильный счёт. Они будут указаны в разделе об оплате.';

  @override
  String get explanationInterestRate =>
      'Мы уточняем процент, чтобы обе стороны одинаково понимали условия. Он будет прописан в договоре вместе с суммой.';

  @override
  String get explanationSalary =>
      'Мы спрашиваем размер оплаты, чтобы он был зафиксирован письменно. Эта сумма будет указана в договоре.';

  @override
  String get explanationPrice =>
      'Мы указываем цену, чтобы обе стороны одинаково понимали стоимость сделки. Эта сумма будет внесена в договор.';

  @override
  String get explanationTransferDate =>
      'Нам нужно знать дату передачи. Она будет указана в договоре и поможет избежать споров о сроках.';

  @override
  String get explanationRepaymentDate =>
      'Мы уточняем, когда нужно вернуть деньги. Эта дата будет указана в договоре, чтобы обе стороны понимали срок.';

  @override
  String get explanationStartDate =>
      'Мы спрашиваем дату начала работы, чтобы зафиксировать её письменно. С этого дня начнут действовать договорённости.';

  @override
  String get explanationDuration =>
      'Мы уточняем срок, чтобы обе стороны понимали, до какого момента действуют договорённости. Эти даты будут указаны в договоре.';

  @override
  String get explanationGenericDate =>
      'Мы спрашиваем дату, чтобы зафиксировать её письменно. Так обе стороны будут понимать, когда что должно произойти.';

  @override
  String get explanationTransferPlace =>
      'Это место будет указано в договоре как место передачи. Так обе стороны будут понимать, где должна состояться сделка.';

  @override
  String get explanationAddress =>
      'Адрес нужен, чтобы в договоре было понятно, о каком именно объекте идёт речь. Он будет указан в описании предмета сделки.';

  @override
  String get explanationVehicleIds =>
      'Этот номер помогает точно указать в договоре, о каком автомобиле идёт речь. Так его нельзя будет перепутать ни с каким другим.';

  @override
  String get explanationVehicleMakeModel =>
      'Мы спрашиваем это, чтобы точно описать автомобиль в договоре. Обе стороны будут понимать, что именно продаётся.';

  @override
  String get explanationPropertyDetails =>
      'Эти детали описывают объект в договоре. Так будет понятно, что именно передаётся, и не возникнет разночтений.';

  @override
  String get explanationPersonalInfo =>
      'Мы спрашиваем это, чтобы в договоре было точно указано, кто участвует в сделке. Без этих данных договор нельзя будет подписать.';

  @override
  String get explanationJobTitle =>
      'Мы уточняем должность, чтобы в договоре было понятно, какую работу вы договорились выполнять. Она будет указана в разделе об обязанностях.';

  @override
  String get explanationContacts =>
      'Контакты нужны, чтобы стороны могли связаться друг с другом. Они будут указаны в конце договора.';

  @override
  String get explanationExtraTerms =>
      'Здесь можно указать любые дополнительные договорённости. Они тоже будут включены в договор.';

  @override
  String get explanationFallback =>
      'Мы спрашиваем это, чтобы договор точно отражал вашу договорённость. Ваш ответ будет вписан в соответствующий пункт документа.';

  @override
  String get interviewAck1 => 'Отлично.';

  @override
  String get interviewAck2 => 'Очень хорошо.';

  @override
  String get interviewAck3 => 'Понятно.';

  @override
  String get interviewAck4 => 'Прекрасно.';

  @override
  String get interviewAck5 => 'Понял.';

  @override
  String get interviewAck6 => 'Принято.';

  @override
  String get interviewAck7 => 'Спасибо.';

  @override
  String get interviewAck8 => 'Хорошо.';

  @override
  String get interviewAck9 => 'Записал.';

  @override
  String get interviewAck10 => 'Теперь всё понятно.';

  @override
  String get interviewAck11 => 'Отмечаю это.';

  @override
  String get interviewAck12 => 'Добавляю в договор.';

  @override
  String get interviewDocAck1 => 'Документ действительно помог.';

  @override
  String get interviewDocAck2 => 'Это сильно сокращает заполнение.';

  @override
  String get interviewDocAck3 => 'Почти всё готово.';

  @override
  String get interviewThinking1 => 'Добавляю это в договор…';

  @override
  String get interviewThinking2 => 'Обновляю договор…';

  @override
  String get interviewThinking3 => 'Проверяю данные…';

  @override
  String get interviewThinking4 => 'Анализирую…';

  @override
  String get interviewThinking5 => 'Сверяю информацию…';

  @override
  String get interviewThinking6 => 'Вношу в документ…';

  @override
  String get interviewScanning1 => 'Читаю документ…';

  @override
  String get interviewScanning2 => 'Распознаю данные…';

  @override
  String get interviewScanning3 => 'Сверяю реквизиты…';

  @override
  String get interviewScanning4 => 'Заполняю договор…';

  @override
  String get interviewGenerationStep1 => 'Проверяю данные';

  @override
  String get interviewGenerationStep2 => 'Анализирую условия';

  @override
  String get interviewGenerationStep3 => 'Формирую договор';

  @override
  String get interviewGenerationStep4 => 'Проверяю юридическую целостность';

  @override
  String get interviewGenerationStep5 => 'Документ готов';

  @override
  String get interviewProgressFirstQuestion => 'Готовим договор…';

  @override
  String get interviewProgressLastQuestion =>
      'Осталось последнее небольшое уточнение.';

  @override
  String get interviewProgressTwoLeft1 => 'Ещё две детали.';

  @override
  String get interviewProgressTwoLeft2 => 'Почти у цели — ещё пара деталей.';

  @override
  String get interviewProgressFewLeft1 => 'Осталось совсем немного.';

  @override
  String get interviewProgressFewLeft2 => 'Уже большая часть готова.';

  @override
  String get interviewProgressFewLeft3 => 'Отличный прогресс.';

  @override
  String get interviewProgressEarly1 => 'Продолжаем…';

  @override
  String get interviewProgressEarly2 => 'Всё идёт отлично.';

  @override
  String get interviewProgressMid1 => 'Договор растёт…';

  @override
  String get interviewProgressMid2 => 'Хороший темп.';

  @override
  String get interviewProgressLate1 => 'Почти готово…';

  @override
  String get interviewProgressLate2 => 'Мы почти закончили.';

  @override
  String interviewGreetingTitle(String templateTitle) {
    return 'Помогу подготовить\n«$templateTitle»';
  }

  @override
  String get interviewGreetingBody =>
      'Я заполню всё, что смогу, автоматически — и спрошу только то, чего не хватает.';

  @override
  String get interviewCelebration1 => 'Отлично! Документ распознан';

  @override
  String get interviewCelebration2 => 'Готово! Я всё прочитал';

  @override
  String get interviewCelebration3 => 'Супер — документ помог';

  @override
  String get interviewCelebration4 => 'Отличное решение';

  @override
  String get interviewCompletionFallback1 => 'Всё необходимое уже собрано.';

  @override
  String get interviewCompletionFallback2 => 'Можно формировать договор.';

  @override
  String get interviewCompletionFallback3 => 'Отличная работа.';

  @override
  String get interviewCompletionFallback4 =>
      'Готово — осталось только подтвердить.';

  @override
  String get interviewConfidenceReliable => 'Надёжно распознано';

  @override
  String get interviewConfidenceCheck => 'Проверьте это значение';

  @override
  String get interviewRemainingAlmostDone => '≈ Почти готово';

  @override
  String get interviewRemainingLastOne => '≈ Осталось последнее уточнение';

  @override
  String interviewRemainingCountFew(int remaining) {
    return '≈ Осталось $remaining небольших уточнения';
  }

  @override
  String interviewRemainingCountMany(int remaining) {
    return '≈ Осталось $remaining небольших уточнений';
  }

  @override
  String interviewTimeSavedSeconds(int seconds) {
    return 'Вы сэкономили примерно $seconds секунд.';
  }

  @override
  String interviewTimeSavedMinutes(int minutes) {
    return 'Вы сэкономили примерно $minutes мин.';
  }

  @override
  String get interviewDocHintVehicle =>
      'Если удобнее, можете также загрузить фотографию техпаспорта — я заполню это и остальные данные автоматически.';

  @override
  String get interviewDocHintRealEstate =>
      'Если документы рядом, можете просто загрузить их фотографию — это быстрее.';

  @override
  String get interviewDocHintBusiness =>
      'Если удобнее, можете загрузить фотографию документа вместо ввода вручную.';

  @override
  String get interviewDocHintEmployment =>
      'Если удобнее, можете загрузить фотографию документа вместо ввода вручную.';

  @override
  String get interviewDocHintBank =>
      'Если удобнее, можете загрузить фотографию реквизитов вместо ввода вручную.';

  @override
  String get interviewDocHintInheritance =>
      'Если удобнее, можете загрузить фотографию свидетельства вместо ввода вручную.';

  @override
  String get interviewDocHintCourt =>
      'Если удобнее, можете загрузить фотографию решения суда вместо ввода вручную.';

  @override
  String get interviewDocHintLoan =>
      'Если удобнее, можете загрузить фотографию договора вместо ввода вручную.';

  @override
  String get interviewDocHintService =>
      'Если удобнее, можете загрузить фотографию документа вместо ввода вручную.';
}
