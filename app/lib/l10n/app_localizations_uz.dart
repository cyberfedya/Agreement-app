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

  @override
  String get commonSave => 'Сақлаш';

  @override
  String get commonSkip => 'Ўтказиб юбориш';

  @override
  String get commonCamera => 'Камера';

  @override
  String get commonGallery => 'Галерея';

  @override
  String get commonUnsupportedPhotoFormat =>
      'Расм форматини аниқлаб бўлмади. JPEG, PNG ёки WebP форматини синаб кўринг.';

  @override
  String get commonUploadFailed => 'Ҳужжатни юклаб бўлмади.';

  @override
  String get documentVerificationTitle => 'Автомобил маълумотларини текширамиз';

  @override
  String get documentVerificationBody =>
      'Агар қўлингизда техпаспорт ёки ПТС бўлса, унинг суратини юкланг. Биз киритилган маълумотлар ҳужжатга мос келишини автоматик текширамиз ва фарқ топсак, огоҳлантирамиз.\n\nБу қадам мажбурий эмас — ҳужжат юкламасдан ҳам шартномани расмийлаштиришни давом эттиришингиз мумкин.';

  @override
  String get documentVerificationUploadButton => 'Техпаспортни юклаш';

  @override
  String get documentVerificationWorking =>
      'Маълумотларни ҳужжат билан солиштиряпман…';

  @override
  String get documentVerificationConflictTitle => 'Фарқ топдик';

  @override
  String get documentVerificationYouEntered => 'Сиз киритдингиз';

  @override
  String get documentVerificationInDocument => 'Ҳужжатда';

  @override
  String get documentVerificationConflictRetryError =>
      'Қийматни сақлаб бўлмади. Яна уриниб кўринг.';

  @override
  String get documentVerificationUseDocumentValue =>
      'Ҳужжатдаги маълумотдан фойдаланиш';

  @override
  String get documentVerificationKeepMine => 'Ўз вариантимни қолдириш';

  @override
  String get documentVerificationCompareFailed =>
      'Ҳужжатни текшириб бўлмади. Яна уриниб кўринг.';

  @override
  String get documentVerificationDoneTitle => 'Текширув якунланди';

  @override
  String get documentVerificationDoneBody =>
      'Ҳужжатдаги маълумотлар сиз киритган маълумотларга тўлиқ мос келади.';

  @override
  String documentVerificationConflictPosition(int position, int total) {
    return '$position / $total';
  }

  @override
  String questionnaireMyDocuments(int count) {
    return 'Менинг ҳужжатларим ($count)';
  }

  @override
  String get questionnaireViewFixOrDelete => 'Кўриш, тузатиш ёки ўчириш';

  @override
  String get questionnaireWhyNeeded => 'Бу нима учун керак?';

  @override
  String get questionnaireGenerateFailed => 'Шартномани яратиб бўлмади.';

  @override
  String get questionnaireReadyToGenerate => 'Шартнома яратишга тайёр';

  @override
  String get questionnaireOneMoment => 'Бир дақиқа…';

  @override
  String get questionnairePreparingNextStep =>
      'Кейинги қадамни тайёрламоқдаман…';

  @override
  String get questionnaireGenerateButton => 'Шартнома яратиш';

  @override
  String get questionnaireAttachDocument => 'Ҳужжат бириктириш';

  @override
  String get questionnaireSend => 'Юбориш';

  @override
  String get questionnaireSpeakOrType => 'Ёзинг ёки айтинг…';

  @override
  String get questionnaireSpeak => 'Овоз чиқариб ўқиш';

  @override
  String get questionnaireRequired => 'Мажбурий';

  @override
  String get questionnaireOptional => 'Мажбурий эмас';

  @override
  String get questionnaireConfirm => 'Тасдиқлаш';

  @override
  String get questionnaireEditAnswer => 'Ўзгартириш';

  @override
  String get questionnaireSayAgain => 'Қайта айтиш';

  @override
  String get questionnaireUploadNotRequired => 'Қўлда киритиш шарт эмас';

  @override
  String get questionnaireUploadDocument => 'Ҳужжат юклаш';

  @override
  String get questionnairePhotographDocument => 'Суратга олиш';

  @override
  String get questionnaireChooseFromGallery => 'Галереядан танлаш';

  @override
  String get questionnaireContinueWithoutDocument => 'Ҳужжатсиз давом этиш';

  @override
  String get questionnaireLiveDocumentTitle =>
      'Шартнома реал вақтда яратилмоқда';

  @override
  String get questionnairePreparingFirstStep =>
      'Биринчи қадамни тайёрламоқдаман…';

  @override
  String get questionnairePreviousStep => 'Олдинги қадам';

  @override
  String questionnaireAlreadyTold(int count) {
    return 'Сиз аллақачон айтдингиз: $count';
  }

  @override
  String get questionnaireListening => 'Тингламоқдаман…';

  @override
  String get questionnaireIUnderstood => 'Мен тушундим:';

  @override
  String get questionnaireUploadNudgeBody =>
      'Агар қулай бўлса, ҳужжат суратини юкланг — бу маълумотларни ўзим тўлдираман.';

  @override
  String get questionnaireUploadNudgeAlt =>
      'Ёки овоз орқали жавоб беринг ёхуд қўлда ёзинг.';

  @override
  String questionnaireInviteMatchedFields(int count) {
    return 'Тахминан $count та майдонни автоматик тўлдираман';
  }

  @override
  String get reviewHeroTitle => 'Шартнома деярли тайёр';

  @override
  String reviewHeroFallback(String templateTitle) {
    return 'Тафсилотларни текширинг — мен «$templateTitle» ни тайёрлайман.';
  }

  @override
  String get reviewDocumentPendingNotice =>
      'Шартномани ҳозир ҳам расмийлаштириш мумкин. Техник маълумотларнинг бир қисми ҳали киритилмаган — кейинроқ техпаспорт юкласангиз, улар автоматик тўлдирилади.';

  @override
  String get reviewAutoFilledStat => 'автоматик\nтўлдирилди';

  @override
  String get reviewManualStatOne => 'саволга ўзингиз\nжавоб бердингиз';

  @override
  String get reviewManualStatMany => 'саволга ўзингиз\nжавоб бердингиз';

  @override
  String get reviewMissingTitle => 'Етишмаяпти';

  @override
  String get reviewMissingSubtitle =>
      'Бу маълумотларсиз шартнома тўлиқ бўлмайди';

  @override
  String get reviewDisputedTitle => '⚠️ Келишиш керак';

  @override
  String get reviewDisputedSubtitle =>
      'Баҳсли қиймат ёки иккинчи тарафнинг таклифи бор — якуний вариантни кўрсатиш учун босинг';

  @override
  String get reviewAutoFilledTitle => '📄 Автоматик тўлдирилди';

  @override
  String get reviewAutoFilledSubtitle => 'Ҳужжатларингиздан';

  @override
  String get reviewCorrectedTitle => '✏️ Сиз томонингиздан тузатилди';

  @override
  String get reviewCorrectedSubtitle =>
      'Ҳужжат аниқлаган маълумотни сиз тузатдингиз';

  @override
  String get reviewManualTitle => '✍️ Ўзингиз киритдингиз';

  @override
  String get reviewSkippedTitle => '⏭️ Талаб қилинмайди';

  @override
  String get reviewSkippedSubtitle =>
      'Тизим томонидан қўйилади ёки сиз учун аҳамиятли эмас';

  @override
  String get reviewTapToFill => 'Киритиш учун босинг';

  @override
  String get reviewEditSaveFailed => 'Ўзгаришни сақлаб бўлмади';

  @override
  String get reviewStatusWaitingSecondParty => 'Иккинчи тарафни кутмоқдамиз';

  @override
  String get reviewStatusWaitingObjectDocument =>
      'Битим объекти бўйича ҳужжат керак';

  @override
  String get reviewStatusMissingMandatoryTerms => 'Мажбурий шартлар етишмайди';

  @override
  String get reviewStatusWaitingPartyAgreement =>
      'Тарафлар шартларни келишмоқда';

  @override
  String get reviewStatusLegalReviewRequired =>
      'Юридик текширув талаб қилинади';

  @override
  String get reviewRiskLowLabel => 'Паст хавф';

  @override
  String get reviewRiskLowMessage => 'Барча асосий маълумотлар киритилган.';

  @override
  String get reviewRiskMediumLabel => 'Ўртача хавф';

  @override
  String get reviewRiskMediumMessage =>
      'Баъзи маълумотлар етишмайди. Шартномани ҳозир расмийлаштириш ёки аниқроқ бўлиши учун аввал қолганини тўлдириш мумкин.';

  @override
  String get reviewRiskHighLabel => 'Юқори хавф';

  @override
  String get reviewRiskHighMessage =>
      'Битимнинг муҳим шартлари етишмайди. Шартномани ҳозир расмийлаштиришимиз мумкин, лекин бу юридик хавфни оширади.';

  @override
  String get profileTitle => 'Профил';

  @override
  String get profileSettingsTooltip => 'Созламалар';

  @override
  String profileLoadFailed(String error) {
    return 'Сақланган профилни юклаб бўлмади: $error';
  }

  @override
  String get profileSaved => 'Профил сақланди';

  @override
  String get profileSaveFailed =>
      'Сақлаб бўлмади. Сервер билан алоқани текширинг.';

  @override
  String get profileIntro =>
      'Бу маълумотлар шартномага сизнинг тарафингиз сифатида қўйилади — бир марта тўлдиринг, интервьюда қайта сўралмайди.';

  @override
  String get profileFullNameLabel => 'Ф.И.Ш.';

  @override
  String get profileFullNameHint => 'Иванов Иван Иванович';

  @override
  String get profilePassportLabel => 'Паспорт серияси ва рақами';

  @override
  String get profilePassportHint => 'AD 1234567';

  @override
  String get profileBirthDateLabel => 'Туғилган сана';

  @override
  String get profileBirthDateHint => '01.01.1990';

  @override
  String get profileAddressLabel => 'Манзил';

  @override
  String get profileAddressHint => 'Тошкент ш., Мисол кўч., 1';

  @override
  String get homeGreetingNight => 'Хайрли тун';

  @override
  String get homeGreetingMorning => 'Хайрли тонг';

  @override
  String get homeGreetingDay => 'Хайрли кун';

  @override
  String get homeGreetingEvening => 'Хайрли кеч';

  @override
  String get homeScanQrTooltip => 'QR сканерлаш';

  @override
  String get homeProfileTooltip => 'Профил';

  @override
  String get homeQuestion => 'Нима ҳақида келишамиз?';

  @override
  String get homeSubtitle =>
      'Сўз ёки овоз билан таърифланг — шартномани автоматик тайёрлайман.';

  @override
  String get homeHint => 'Нима ҳақида келишмоқчи эканингизни ёзинг ёки айтинг…';

  @override
  String get homeListening => 'Тингламоқдаман…';

  @override
  String get homeHoldToTalk => 'Гапириш учун ушлаб туринг';

  @override
  String get homeCreateAgreement => 'Шартнома яратиш';

  @override
  String get authTagline => 'Юридик кучга эга шартномалар';

  @override
  String get authMyIdTitle => 'MyID орқали идентификация';

  @override
  String get authMyIdBody =>
      'Исмингиз, фамилиянгиз ва паспорт маълумотларингиз MyID орқали тасдиқланади ва шартномага автоматик қўйилади.';

  @override
  String get authContinueWithMyId => 'MyID билан давом этиш';

  @override
  String get authVerifying => 'Маълумотлар текширилмоқда…';

  @override
  String get authDemoModeNotice =>
      'Демо режим — ҳақиқий интеграция кейинроқ қўшилади';

  @override
  String get commonPdf => 'PDF';

  @override
  String get commonSend => 'Юбориш';

  @override
  String get commonBack => 'Орқага';

  @override
  String get commonDecline => 'Рад этиш';

  @override
  String get commonHome => 'Бош саҳифага';

  @override
  String get commonCopy => 'Нусха олиш';

  @override
  String get agreementCopied => 'Шартнома нусхаланди';

  @override
  String get agreementFirstPartyFallback => 'Биринчи томон';

  @override
  String get agreementSignFailed => 'Шартномани имзолаб бўлмади.';

  @override
  String get agreementTitle => 'Шартнома';

  @override
  String get agreementNotCreatedTitle => 'Шартнома ҳали яратилмаган';

  @override
  String get agreementNotCreatedMessage =>
      'Интервьюдан ўтинг ва шартнома яратинг — у шу ерда пайдо бўлади.';

  @override
  String get agreementYouSignedWaitingSecond =>
      'Сиз шартномани имзоладингиз.\nИккинчи тарафни кутмоқдамиз.';

  @override
  String get agreementSecondSignedWaitingYou =>
      'Иккинчи тараф шартномани аллақачон имзолади.\nЯкунлаш учун имзоланг.';

  @override
  String get agreementQrInstructions =>
      'Ушбу QR-кодни иккинчи тарафга кўрсатинг — у уни сканерлайди, MyID орқали идентификациядан ўтади ва шартномани имзолайди.';

  @override
  String agreementCreatedAt(String time) {
    return 'Яратилди $time';
  }

  @override
  String get agreementCopyTextTooltip => 'Матнни нусхалаш';

  @override
  String get agreementSharePdfTooltip => 'Улашиш / PDF';

  @override
  String get agreementYouSigned => 'Сиз шартномани имзоладингиз';

  @override
  String get agreementSignButton => 'Шартномани имзолаш';

  @override
  String get agreementOpenAsSecondParty =>
      'Иккинчи тараф сифатида очиш (шу қурилмада)';

  @override
  String get agreementWaitingBothSignatures =>
      'Икки тараф имзосини кутмоқдамиз';

  @override
  String get agreementWaitingSecondSignature =>
      'Иккинчи тараф имзосини кутмоқдамиз';

  @override
  String get agreementBothSigned => 'Икки тараф ҳам имзолади';

  @override
  String get agreementStepCreated => 'Яратилди';

  @override
  String get agreementStepCompleted => 'Якунланди';

  @override
  String agreementSignProposalSent(String label) {
    return '«$label» бўйича таклиф иккинчи тарафга юборилди.';
  }

  @override
  String get agreementSignQuestionSent => 'Савол иккинчи тарафга юборилди.';

  @override
  String get agreementSignDemoName => 'Иванов Иван Иванович';

  @override
  String get agreementDocumentUnavailableTitle => 'Ҳужжат мавжуд эмас';

  @override
  String get agreementNotFoundOrNotGenerated =>
      'Бу шартнома топилмади ёки ҳали яратилмаган.';

  @override
  String get agreementSignTitle => 'Имзолаш учун шартнома';

  @override
  String get agreementFullySigned => 'Шартнома тўлиқ имзоланди.';

  @override
  String get agreementSecondPartySignedWaitingFirst =>
      'Сиз шартномани имзоладингиз.\nБиринчи тарафни кутмоқдамиз.';

  @override
  String get agreementFirstPartySignedWaitingSecond =>
      'Биринчи тараф шартномани аллақачон имзолади.\nЯкунлаш учун имзоланг.';

  @override
  String get agreementMyIdNotice =>
      'Имзолашдан олдин — MyID орқали идентификация. Исм ва маълумотларингиз шартномага автоматик қўйилади.';

  @override
  String get agreementProposeChange => 'Шартни ўзгартириш';

  @override
  String get agreementAskQuestion => 'Савол бериш';

  @override
  String get agreementSignWithMyId => 'MyID орқали ўтиш ва имзолаш';

  @override
  String get agreementNotFoundTitle => 'Шартнома топилмади';

  @override
  String get agreementNotFoundMessage =>
      'Афтидан, бу ерга тўғридан-тўғри кирдингиз. Бош саҳифадан янги битим бошланг.';

  @override
  String get agreementSignedSuccessfully => 'Шартнома муваффақиятли имзоланди';

  @override
  String agreementSignedBy(String name) {
    return 'Имзолади: $name';
  }

  @override
  String get agreementPdfExportFailed =>
      'PDF яратиб бўлмади. Яна уриниб кўринг.';

  @override
  String get dealInviteFillProfileFirst =>
      'Аввал ўз маълумотларингизни тўлдиринг — улар шартномада кўрсатилади.';

  @override
  String get dealInviteRegenerateFailed =>
      'Шартномани маълумотларингиз билан янгилаб бўлмади.';

  @override
  String get dealInviteTitle => 'Битимга таклиф';

  @override
  String get dealInviteHeadline =>
      'Сиз битимда иштирок этишга таклиф қилиндингиз';

  @override
  String get dealInviteTypeLabel => 'Битим тури';

  @override
  String get dealInviteYourRoleLabel => 'Сизнинг ролингиз';

  @override
  String get dealInviteInvitedByLabel => 'Таклиф қилди';

  @override
  String get dealInviteNotSpecified => 'Кўрсатилмаган';

  @override
  String get dealInviteStatusLabel => 'Ҳолати';

  @override
  String get dealInviteAccept => 'Қабул қилиш';

  @override
  String get dealInviteDeclineDialogTitle => 'Таклифни рад этасизми?';

  @override
  String get dealInviteDeclineDialogBody =>
      'Иккинчи тараф жавобингизни кўради. Қисқача сабабини ёзишингиз мумкин — бу мажбурий эмас.';

  @override
  String get dealInviteDeclineReasonHint => 'Сабаб (мажбурий эмас)…';

  @override
  String get dealInviteDeclined => 'Сиз таклифни рад этдингиз';

  @override
  String get dealInviteStatusPending => 'Тасдиқлашни кутмоқда';

  @override
  String get dealInviteStatusOpened => 'Очилган';

  @override
  String get dealInviteStatusAccepted => 'Қабул қилинган';

  @override
  String get dealInviteStatusDeclined => 'Рад этилган';

  @override
  String get dealInviteStatusChangeRequested => 'Ўзгартириш таклиф қилинган';

  @override
  String get dealInviteStatusClarificationRequested => 'Аниқлаштириш сўралган';

  @override
  String get roleSeller => 'Сотувчи';

  @override
  String get roleBuyer => 'Харидор';

  @override
  String get roleLandlord => 'Ижарага берувчи';

  @override
  String get roleTenant => 'Ижарага олувчи';

  @override
  String get roleLender => 'Қарз берувчи';

  @override
  String get roleBorrower => 'Қарз олувчи';

  @override
  String get roleEmployer => 'Иш берувчи';

  @override
  String get roleEmployee => 'Ходим';

  @override
  String get roleCustomer => 'Буюртмачи';

  @override
  String get roleContractor => 'Пудратчи';

  @override
  String get roleDonor => 'Ҳадя қилувчи';

  @override
  String get roleRecipient => 'Ҳадя олувчи';

  @override
  String get roleFirstParty => 'Биринчи томон';

  @override
  String get roleSecondParty => 'Иккинчи томон';

  @override
  String get roleParticipant => 'Битим иштирокчиси';

  @override
  String get negotiationWhatToChange => 'Нимани ўзгартирмоқчисиз?';

  @override
  String get negotiationChooseTerm =>
      'Шартнома шартини танланг — таклифингизни иккинчи тараф кўради.';

  @override
  String get negotiationNoEditableTerms =>
      'Ҳозирча ўзгартирса бўладиган шартлар йўқ.';

  @override
  String get negotiationBackToList => 'Шартлар рўйхатига';

  @override
  String get negotiationCurrentValue => 'Ҳозир шартномада';

  @override
  String get negotiationYourProposalHint => 'Таклифингиз…';

  @override
  String get negotiationReasonHint => 'Нима учун? (мажбурий эмас)';

  @override
  String get negotiationSendProposal => 'Таклифни юбориш';

  @override
  String get negotiationAskQuestionTitle => 'Савол бериш';

  @override
  String get negotiationAskQuestionBody =>
      'Имзолашдан олдин аниқлаштирмоқчи бўлган нарсангизни сўранг — саволни иккинчи тараф кўради.';

  @override
  String get negotiationQuestionHint => 'Саволингиз…';

  @override
  String get documentsUploadedTitle => 'Юкланган ҳужжатлар';

  @override
  String get documentsEmptyState =>
      'Ҳали ҳужжатлар йўқ. Скрепка орқали расм илова қилинг — маълумотларни автоматик тўлдираман.';

  @override
  String get documentsDeleteDialogTitle => 'Ҳужжат ўчирилсинми?';

  @override
  String documentsDeleteDialogBody(String fileName) {
    return '«$fileName» ва ундан аниқланган барча маълумотлар битимдан ўчирилади.';
  }

  @override
  String get documentsDeleteTooltip => 'Ҳужжатни ўчириш';

  @override
  String get documentsRecognitionFailed => 'Ҳужжатни аниқлаб бўлмади.';

  @override
  String get templatesTitle => 'Шартнома шаблонлари';

  @override
  String get templatesNothingFoundTitle => 'Ҳеч нарса топилмади';

  @override
  String get templatesNothingFoundMessage =>
      'Бошқа сўров ёки категорияни синаб кўринг.';

  @override
  String get templatesResetFilters => 'Филтрларни тозалаш';

  @override
  String get templatesAll => 'Барчаси';

  @override
  String get templateDetailTitle => 'Шартнома шаблони';

  @override
  String get templateDetailNotFoundTitle => 'Шаблон топилмади';

  @override
  String get templateDetailNotFoundMessage =>
      'Бу шартнома шаблони мавжуд эмас.';

  @override
  String get templateDetailCategoryLabel => 'Категория';

  @override
  String get templateDetailQuestionsLabel => 'Саволлар';

  @override
  String get templateDetailTimeLabel => 'Вақт';

  @override
  String templateDetailTimeValue(int minutes) {
    return '~$minutes дақ';
  }

  @override
  String get templateDetailAboutTitle => 'Бу шартнома ҳақида';

  @override
  String get templateDetailSourceTitle => 'Манба';

  @override
  String get templateDetailContinue => 'Давом этиш';

  @override
  String get qrTitle => 'QR-кодни сканерлаш';

  @override
  String get qrNotAgreementCode => 'Бу EasyAgree шартнома QR-коди эмас';

  @override
  String get qrHint => 'Камерани шартнома QR-кодига йўналтиринг';

  @override
  String get qrCameraPermissionNeeded =>
      'Шартнома QR-кодини сканерлаш учун камерага рухсат керак.';

  @override
  String get qrAllowAccess => 'Рухсат бериш';

  @override
  String get onboardingSlide1Title =>
      'Шунчаки нима ҳақида\nкелишаётганингизни айтинг';

  @override
  String get onboardingSlide1Body =>
      'Ўз сўзларингиз ёки овоз билан — сунъий интеллект қандай шартнома кераклигини тушунади ва тайёрлайди.';

  @override
  String get onboardingSlide2Title =>
      'Ҳужжатни суратга олинг —\nқолгани ўзи тўлдирилади';

  @override
  String get onboardingSlide2Body =>
      'Техпаспорт, кадастр ҳужжатлари, реквизитлар: сунъий интеллект уларни аниқлаб, шартномани автоматик тўлдиради.';

  @override
  String get onboardingSlide3Title => 'Иккинчи тараф QR-код\nорқали имзолайди';

  @override
  String get onboardingSlide3Body =>
      'Кодни кўрсатинг — шериги шартномани ўзида очади, ўзгартириш таклиф қилади ёки дарҳол имзолайди.';

  @override
  String get onboardingSkip => 'Ўтказиб юбориш';

  @override
  String get onboardingStart => 'Бошлаш';

  @override
  String get onboardingNext => 'Кейинги';

  @override
  String get appEmptyStateDefaultTitle => 'Бу ерда ҳали бўш';

  @override
  String get appErrorTitle => 'Нимадир хато кетди';

  @override
  String get appErrorRetry => 'Қайта уриниш';

  @override
  String get searchHint => 'Шартномаларни қидириш…';

  @override
  String get searchClearTooltip => 'Тозалаш';

  @override
  String progressStepOf(int current, int total) {
    return '$total дан $current';
  }

  @override
  String get routeNotFoundTitle => 'Саҳифа топилмади';

  @override
  String routeNotFoundMessage(String routeName) {
    return '\"$routeName\" экрани ушбу сборкада мавжуд эмас.';
  }

  @override
  String get categoryVehicle => 'Транспорт';

  @override
  String get categoryRealEstate => 'Кўчмас мулк';

  @override
  String get categoryRent => 'Ижара';

  @override
  String get categoryEmployment => 'Иш';

  @override
  String get categoryLoan => 'Қарз';

  @override
  String get categoryService => 'Хизматлар';

  @override
  String get categoryGift => 'Тортиқ қилиш';

  @override
  String get categoryFamily => 'Оила';

  @override
  String get categoryConstruction => 'Қурилиш';

  @override
  String get categoryPowerOfAttorney => 'Ишончнома';

  @override
  String get categoryBusiness => 'Бизнес';

  @override
  String get categorySale => 'Олди-сотди';

  @override
  String get aiProcessingStep1 => 'Маълумотни таҳлил қиляпмиз…';

  @override
  String get aiProcessingStep2 => 'Шартнома тузилмасини шакллантиряпмиз…';

  @override
  String get aiProcessingStep3 => 'Зарур шартларни аниқляпмиз…';

  @override
  String get aiProcessingStep4 => 'Деярли тайёр…';

  @override
  String get aiProcessingServerError => 'Серверга уланиб бўлмади.';

  @override
  String get aiProcessingNoMatchTitle => 'Шартнома турини аниқлаб бўлмади';

  @override
  String get aiProcessingNoMatchBody =>
      'Нима ҳақида келишмоқчи эканингизни батафсилроқ ёзинг — масалан, «автомобиль сотаман» ёки «квартирани ижарага бераман».';

  @override
  String get aiProcessingEditRequest => 'Сўровни ўзгартириш';

  @override
  String extractionFilledSummary(int count, String plural, String remaining) {
    return '$count $plural автоматик тўлдирилди — уларни қўлда киритишингиз шарт эмас. $remaining';
  }

  @override
  String get extractionPluralFieldOne => 'маълумот';

  @override
  String get extractionPluralFieldFew => 'маълумот';

  @override
  String get extractionPluralFieldMany => 'маълумот';

  @override
  String get extractionRemainingUnknown =>
      'Яна бир нечта деталь аниқлаштириш қолди.';

  @override
  String get extractionRemainingNone =>
      'Саволлар қолмади — шартнома деярли тайёр.';

  @override
  String get extractionRemainingOne => 'Атиги битта деталь қолди.';

  @override
  String extractionRemainingFew(int n) {
    return 'Атиги $n та деталь қолди.';
  }

  @override
  String extractionRemainingMany(int n) {
    return '$n та деталь қолди.';
  }

  @override
  String extractionAndMore(int count) {
    return 'яна $count…';
  }

  @override
  String get extractionContinue => 'Давом этиш';
}
