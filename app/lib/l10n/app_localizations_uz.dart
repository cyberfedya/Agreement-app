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
}
