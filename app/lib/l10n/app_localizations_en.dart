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

  @override
  String get commonSave => 'Save';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonCamera => 'Camera';

  @override
  String get commonGallery => 'Gallery';

  @override
  String get commonUnsupportedPhotoFormat =>
      'Couldn\'t recognize the photo format. Try JPEG, PNG or WebP.';

  @override
  String get commonUploadFailed => 'Couldn\'t upload the document.';

  @override
  String get documentVerificationTitle => 'Let\'s check the vehicle\'s details';

  @override
  String get documentVerificationBody =>
      'If you have the vehicle\'s registration certificate, upload a photo of it. We\'ll automatically check whether what you entered matches the document, and flag anything that doesn\'t.\n\nThis step is optional — you can continue without uploading a document.';

  @override
  String get documentVerificationUploadButton =>
      'Upload registration certificate';

  @override
  String get documentVerificationWorking => 'Checking against the document…';

  @override
  String get documentVerificationConflictTitle => 'We found a difference';

  @override
  String get documentVerificationYouEntered => 'You entered';

  @override
  String get documentVerificationInDocument => 'In the document';

  @override
  String get documentVerificationConflictRetryError =>
      'Couldn\'t save the value. Please try again.';

  @override
  String get documentVerificationUseDocumentValue =>
      'Use the document\'s value';

  @override
  String get documentVerificationKeepMine => 'Keep my value';

  @override
  String get documentVerificationCompareFailed =>
      'Couldn\'t check the document. Please try again.';

  @override
  String get documentVerificationDoneTitle => 'Check complete';

  @override
  String get documentVerificationDoneBody =>
      'The document matches what you entered.';

  @override
  String documentVerificationConflictPosition(int position, int total) {
    return '$position of $total';
  }

  @override
  String questionnaireMyDocuments(int count) {
    return 'My documents ($count)';
  }

  @override
  String get questionnaireViewFixOrDelete => 'View, fix or delete';

  @override
  String get questionnaireWhyNeeded => 'Why do we need this?';

  @override
  String get questionnaireGenerateFailed => 'Couldn\'t create the agreement.';

  @override
  String get questionnaireReadyToGenerate =>
      'The agreement is ready to be created';

  @override
  String get questionnaireOneMoment => 'One moment…';

  @override
  String get questionnairePreparingNextStep => 'Preparing the next step…';

  @override
  String get questionnaireGenerateButton => 'Create agreement';

  @override
  String get questionnaireAttachDocument => 'Attach a document';

  @override
  String get questionnaireSend => 'Send';

  @override
  String get questionnaireSpeakOrType => 'Type or say something…';

  @override
  String get questionnaireSpeak => 'Read aloud';

  @override
  String get questionnaireRequired => 'Required';

  @override
  String get questionnaireOptional => 'Optional';

  @override
  String get questionnaireConfirm => 'Confirm';

  @override
  String get questionnaireEditAnswer => 'Edit';

  @override
  String get questionnaireSayAgain => 'Say it again';

  @override
  String get questionnaireUploadNotRequired => 'No need to type it manually';

  @override
  String get questionnaireUploadDocument => 'Upload document';

  @override
  String get questionnairePhotographDocument => 'Take a photo';

  @override
  String get questionnaireChooseFromGallery => 'Choose from gallery';

  @override
  String get questionnaireContinueWithoutDocument =>
      'Continue without a document';

  @override
  String get questionnaireLiveDocumentTitle =>
      'Your agreement is being built in real time';

  @override
  String get questionnairePreparingFirstStep => 'Preparing the first step…';

  @override
  String get questionnairePreviousStep => 'Previous step';

  @override
  String questionnaireAlreadyTold(int count) {
    return 'You\'ve already told us: $count';
  }

  @override
  String get questionnaireListening => 'Listening…';

  @override
  String get questionnaireIUnderstood => 'I heard:';

  @override
  String get questionnaireUploadNudgeBody =>
      'If it\'s easier, upload a photo of the document — I\'ll fill this in automatically.';

  @override
  String get questionnaireUploadNudgeAlt =>
      'Or just answer by voice or type it in.';

  @override
  String questionnaireInviteMatchedFields(int count) {
    return 'I\'ll fill in about $count fields automatically';
  }

  @override
  String get reviewHeroTitle => 'Almost ready';

  @override
  String reviewHeroFallback(String templateTitle) {
    return 'Check the details — then I\'ll prepare «$templateTitle».';
  }

  @override
  String get reviewDocumentPendingNotice =>
      'You can already create the agreement. Some technical details are still missing — if you upload the registration certificate later, they\'ll fill in automatically.';

  @override
  String get reviewAutoFilledStat => 'filled in\nautomatically';

  @override
  String get reviewManualStatOne => 'question you\nanswered yourself';

  @override
  String get reviewManualStatMany => 'questions you\nanswered yourself';

  @override
  String get reviewMissingTitle => 'Missing';

  @override
  String get reviewMissingSubtitle =>
      'Without this, the agreement would be incomplete';

  @override
  String get reviewDisputedTitle => '⚠️ Needs agreement';

  @override
  String get reviewDisputedSubtitle =>
      'There\'s a disputed value or a proposal from the other party — tap to set the final one';

  @override
  String get reviewAutoFilledTitle => '📄 Filled in automatically';

  @override
  String get reviewAutoFilledSubtitle => 'From your documents';

  @override
  String get reviewCorrectedTitle => '✏️ Corrected by you';

  @override
  String get reviewCorrectedSubtitle =>
      'You corrected what the document detected';

  @override
  String get reviewManualTitle => '✍️ You entered this yourself';

  @override
  String get reviewSkippedTitle => '⏭️ Not required';

  @override
  String get reviewSkippedSubtitle =>
      'Filled in by the system, or not relevant to your case';

  @override
  String get reviewTapToFill => 'Tap to fill in';

  @override
  String get reviewEditSaveFailed => 'Couldn\'t save the change';

  @override
  String get reviewStatusWaitingSecondParty => 'Waiting for the other party';

  @override
  String get reviewStatusWaitingObjectDocument =>
      'A document about the subject of the deal is needed';

  @override
  String get reviewStatusMissingMandatoryTerms =>
      'Some mandatory terms are missing';

  @override
  String get reviewStatusWaitingPartyAgreement =>
      'The parties are agreeing on terms';

  @override
  String get reviewStatusLegalReviewRequired => 'Legal review required';

  @override
  String get reviewRiskLowLabel => 'Low risk';

  @override
  String get reviewRiskLowMessage => 'All key details are filled in.';

  @override
  String get reviewRiskMediumLabel => 'Medium risk';

  @override
  String get reviewRiskMediumMessage =>
      'Some details are missing. You can create the agreement now, or fill in the rest first for more accuracy.';

  @override
  String get reviewRiskHighLabel => 'High risk';

  @override
  String get reviewRiskHighMessage =>
      'Important deal terms are missing. We can still create the agreement now, but that increases legal risk.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSettingsTooltip => 'Settings';

  @override
  String profileLoadFailed(String error) {
    return 'Couldn\'t load your saved profile: $error';
  }

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileSaveFailed =>
      'Couldn\'t save. Check your connection to the server.';

  @override
  String get profileIntro =>
      'This information fills in your side of the agreement — fill it in once and it won\'t be asked again during the interview.';

  @override
  String get profileFullNameLabel => 'Full name';

  @override
  String get profileFullNameHint => 'John Smith';

  @override
  String get profilePassportLabel => 'Passport series and number';

  @override
  String get profilePassportHint => 'AD 1234567';

  @override
  String get profileBirthDateLabel => 'Date of birth';

  @override
  String get profileBirthDateHint => '01.01.1990';

  @override
  String get profileAddressLabel => 'Address';

  @override
  String get profileAddressHint => '123 Example St, Tashkent';

  @override
  String get homeGreetingNight => 'Good night';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingDay => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeScanQrTooltip => 'Scan QR';

  @override
  String get homeProfileTooltip => 'Profile';

  @override
  String get homeQuestion => 'What are you agreeing on?';

  @override
  String get homeSubtitle =>
      'Describe it in words or by voice — I\'ll prepare the agreement automatically.';

  @override
  String get homeHint => 'Say or type what you\'d like to agree on…';

  @override
  String get homeListening => 'Listening…';

  @override
  String get homeHoldToTalk => 'Hold to talk';

  @override
  String get homeCreateAgreement => 'Create agreement';

  @override
  String get authTagline => 'Legally binding agreements';

  @override
  String get authMyIdTitle => 'Identification via MyID';

  @override
  String get authMyIdBody =>
      'Your name and passport details will be verified through MyID and automatically filled into the agreement.';

  @override
  String get authContinueWithMyId => 'Continue with MyID';

  @override
  String get authVerifying => 'Verifying your details…';

  @override
  String get authDemoModeNotice =>
      'Demo mode — real integration is coming later';
}
