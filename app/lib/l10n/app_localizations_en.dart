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
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

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
  String get documentCaptureTitle => 'Document photo';

  @override
  String get documentCaptureAddPage => 'Another photo';

  @override
  String get documentCaptureRetake => 'Retake';

  @override
  String get documentCaptureContinue => 'Continue';

  @override
  String get documentCaptureEmptyHint =>
      'Take a photo of the document - you can add more pages if needed.';

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
  String get profileFullNameHint => 'Last name First name Middle name';

  @override
  String get profilePassportLabel => 'Passport series and number';

  @override
  String get profilePassportHint => 'Series and number';

  @override
  String get profilePassportInvalid =>
      'Format: two letters and seven digits, e.g. AB1234567.';

  @override
  String get profileBirthDateLabel => 'Date of birth';

  @override
  String get profileBirthDateHint => 'DD.MM.YYYY';

  @override
  String get profileAddressLabel => 'Address';

  @override
  String get profileAddressHint => 'City, street, building';

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

  @override
  String get commonPdf => 'PDF';

  @override
  String get commonSend => 'Send';

  @override
  String get commonBack => 'Back';

  @override
  String get commonDecline => 'Decline';

  @override
  String get commonHome => 'Home';

  @override
  String get commonCopy => 'Copy';

  @override
  String get agreementCopied => 'Agreement copied';

  @override
  String get agreementFirstPartyFallback => 'First party';

  @override
  String get agreementSignFailed => 'Couldn\'t sign the agreement.';

  @override
  String get agreementTitle => 'Agreement';

  @override
  String get agreementNotCreatedTitle =>
      'The agreement hasn\'t been created yet';

  @override
  String get agreementNotCreatedMessage =>
      'Complete the interview and create the agreement — it will appear here.';

  @override
  String get agreementYouSignedWaitingSecond =>
      'You\'ve signed the agreement.\nWaiting for the other party.';

  @override
  String get agreementSecondSignedWaitingYou =>
      'The other party has already signed.\nSign to complete the agreement.';

  @override
  String get agreementQrInstructions =>
      'Show this QR code to the other party — they\'ll scan it, verify with MyID, and sign the agreement.';

  @override
  String agreementCreatedAt(String time) {
    return 'Created $time';
  }

  @override
  String get agreementCopyTextTooltip => 'Copy text';

  @override
  String get agreementSharePdfTooltip => 'Share / PDF';

  @override
  String get agreementYouSigned => 'You\'ve signed the agreement';

  @override
  String get agreementSignButton => 'Sign agreement';

  @override
  String get agreementOpenAsSecondParty =>
      'Open as the other party (on this device)';

  @override
  String get agreementWaitingBothSignatures => 'Waiting for both signatures';

  @override
  String get agreementWaitingSecondSignature =>
      'Waiting for the other party\'s signature';

  @override
  String get agreementBothSigned => 'Both parties signed';

  @override
  String get agreementStepCreated => 'Created';

  @override
  String get agreementStepCompleted => 'Completed';

  @override
  String agreementSignProposalSent(String label) {
    return 'Your proposal for «$label» was sent to the other party.';
  }

  @override
  String get agreementSignQuestionSent =>
      'Your question was sent to the other party.';

  @override
  String get agreementSignDemoName => 'John Smith';

  @override
  String get agreementDocumentUnavailableTitle => 'Document unavailable';

  @override
  String get agreementNotFoundOrNotGenerated =>
      'This agreement wasn\'t found or hasn\'t been generated yet.';

  @override
  String get agreementSignTitle => 'Agreement to sign';

  @override
  String get agreementFullySigned => 'The agreement is fully signed.';

  @override
  String get agreementSecondPartySignedWaitingFirst =>
      'You\'ve signed the agreement.\nWaiting for the first party.';

  @override
  String get agreementFirstPartySignedWaitingSecond =>
      'The first party has already signed.\nSign to complete the agreement.';

  @override
  String get agreementMyIdNotice =>
      'Before signing — identification via MyID. Your name and details will be filled into the agreement automatically.';

  @override
  String get agreementProposeChange => 'Change a term';

  @override
  String get agreementAskQuestion => 'Ask a question';

  @override
  String get agreementSignWithMyId => 'Verify with MyID and sign';

  @override
  String get agreementNotFoundTitle => 'Agreement not found';

  @override
  String get agreementNotFoundMessage =>
      'Looks like you landed here directly. Start a new deal from the home screen.';

  @override
  String get agreementSignedSuccessfully => 'Agreement signed successfully';

  @override
  String agreementSignedBy(String name) {
    return 'Signed by: $name';
  }

  @override
  String get agreementPdfExportFailed =>
      'Couldn\'t create the PDF. Please try again.';

  @override
  String get dealInviteFillProfileFirst =>
      'First fill in your details — they\'ll appear in the agreement.';

  @override
  String get dealInviteRegenerateFailed =>
      'Couldn\'t update the agreement with your details.';

  @override
  String get dealInviteTitle => 'Deal invitation';

  @override
  String get dealInviteHeadline =>
      'You\'ve been invited to take part in a deal';

  @override
  String get dealInviteTypeLabel => 'Deal type';

  @override
  String get dealInviteYourRoleLabel => 'Your role';

  @override
  String get dealInviteInvitedByLabel => 'Invited by';

  @override
  String get dealInviteNotSpecified => 'Not specified';

  @override
  String get dealInviteStatusLabel => 'Status';

  @override
  String get dealInviteAccept => 'Accept';

  @override
  String get dealInviteDeclineDialogTitle => 'Decline the invitation?';

  @override
  String get dealInviteDeclineDialogBody =>
      'The other party will see your response. You can briefly explain why — this is optional.';

  @override
  String get dealInviteDeclineReasonHint => 'Reason (optional)…';

  @override
  String get dealInviteDeclined => 'You declined the invitation';

  @override
  String get dealInviteStatusPending => 'Awaiting confirmation';

  @override
  String get dealInviteStatusOpened => 'Opened';

  @override
  String get dealInviteStatusAccepted => 'Accepted';

  @override
  String get dealInviteStatusDeclined => 'Declined';

  @override
  String get dealInviteStatusChangeRequested => 'Changes proposed';

  @override
  String get dealInviteStatusClarificationRequested =>
      'Clarification requested';

  @override
  String get roleSeller => 'Seller';

  @override
  String get roleBuyer => 'Buyer';

  @override
  String get roleLandlord => 'Landlord';

  @override
  String get roleTenant => 'Tenant';

  @override
  String get roleLender => 'Lender';

  @override
  String get roleBorrower => 'Borrower';

  @override
  String get roleEmployer => 'Employer';

  @override
  String get roleEmployee => 'Employee';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get roleContractor => 'Contractor';

  @override
  String get roleDonor => 'Donor';

  @override
  String get roleRecipient => 'Recipient';

  @override
  String get roleFirstParty => 'First party';

  @override
  String get roleSecondParty => 'Second party';

  @override
  String get roleParticipant => 'Deal participant';

  @override
  String get negotiationWhatToChange => 'What would you like to change?';

  @override
  String get negotiationChooseTerm =>
      'Choose a term of the agreement — the other party will see your proposal.';

  @override
  String get negotiationNoEditableTerms =>
      'There are no terms available to change yet.';

  @override
  String get negotiationBackToList => 'Back to the list of terms';

  @override
  String get negotiationCurrentValue => 'Currently in the agreement';

  @override
  String get negotiationYourProposalHint => 'Your proposal…';

  @override
  String get negotiationReasonHint => 'Why? (optional)';

  @override
  String get negotiationSendProposal => 'Send proposal';

  @override
  String get negotiationAskQuestionTitle => 'Ask a question';

  @override
  String get negotiationAskQuestionBody =>
      'Ask what you\'d like to clarify before signing — the other party will see your question.';

  @override
  String get negotiationQuestionHint => 'Your question…';

  @override
  String get documentsUploadedTitle => 'Uploaded documents';

  @override
  String get documentsEmptyState =>
      'No documents yet. Attach a photo via the paperclip — I\'ll fill in the data automatically.';

  @override
  String get documentsDeleteDialogTitle => 'Delete document?';

  @override
  String documentsDeleteDialogBody(String fileName) {
    return '\"$fileName\" and all data recognized from it will be removed from the deal.';
  }

  @override
  String get documentsDeleteTooltip => 'Delete document';

  @override
  String get documentsRecognitionFailed => 'Failed to recognize the document.';

  @override
  String get templatesTitle => 'Agreement templates';

  @override
  String get templatesNothingFoundTitle => 'Nothing found';

  @override
  String get templatesNothingFoundMessage =>
      'Try a different search or category.';

  @override
  String get templatesResetFilters => 'Reset filters';

  @override
  String get templatesAll => 'All';

  @override
  String get templateDetailTitle => 'Agreement template';

  @override
  String get templateDetailNotFoundTitle => 'Template not found';

  @override
  String get templateDetailNotFoundMessage =>
      'This agreement template is unavailable.';

  @override
  String get templateDetailCategoryLabel => 'Category';

  @override
  String get templateDetailQuestionsLabel => 'Questions';

  @override
  String get templateDetailTimeLabel => 'Time';

  @override
  String templateDetailTimeValue(int minutes) {
    return '~$minutes min';
  }

  @override
  String get templateDetailAboutTitle => 'About this agreement';

  @override
  String get templateDetailSourceTitle => 'Source';

  @override
  String get templateDetailContinue => 'Continue';

  @override
  String get qrTitle => 'Scan QR code';

  @override
  String get qrNotAgreementCode => 'This is not an EasyAgree deal QR code';

  @override
  String get qrHint => 'Point the camera at the deal QR code';

  @override
  String get qrCameraPermissionNeeded =>
      'Camera access is needed to scan the deal QR code.';

  @override
  String get qrAllowAccess => 'Allow access';

  @override
  String get onboardingSlide1Title => 'Just say what\nyou\'re agreeing on';

  @override
  String get onboardingSlide1Body =>
      'In your own words or by voice — the AI will figure out which agreement you need and prepare it.';

  @override
  String get onboardingSlide2Title =>
      'Photograph a document —\nthe rest fills in itself';

  @override
  String get onboardingSlide2Body =>
      'Vehicle registration, property documents, details: the AI recognizes them and fills in the agreement automatically.';

  @override
  String get onboardingSlide3Title => 'The other party signs\nvia QR code';

  @override
  String get onboardingSlide3Body =>
      'Show the code — your partner opens the agreement on their device, proposes changes, or signs right away.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingNext => 'Next';

  @override
  String get appEmptyStateDefaultTitle => 'Nothing here yet';

  @override
  String get appErrorTitle => 'Something went wrong';

  @override
  String get appErrorRetry => 'Retry';

  @override
  String get searchHint => 'Search agreements…';

  @override
  String get searchClearTooltip => 'Clear';

  @override
  String progressStepOf(int current, int total) {
    return '$current of $total';
  }

  @override
  String get routeNotFoundTitle => 'Page not found';

  @override
  String routeNotFoundMessage(String routeName) {
    return 'The screen \"$routeName\" doesn\'t exist in this build.';
  }

  @override
  String get categoryVehicle => 'Vehicle';

  @override
  String get categoryRealEstate => 'Real estate';

  @override
  String get categoryRent => 'Rental';

  @override
  String get categoryEmployment => 'Employment';

  @override
  String get categoryLoan => 'Loans';

  @override
  String get categoryService => 'Services';

  @override
  String get categoryGift => 'Gifting';

  @override
  String get categoryFamily => 'Family';

  @override
  String get categoryConstruction => 'Construction';

  @override
  String get categoryPowerOfAttorney => 'Power of attorney';

  @override
  String get categoryBusiness => 'Business';

  @override
  String get categorySale => 'Sale';

  @override
  String get aiProcessingStep1 => 'Analyzing your request…';

  @override
  String get aiProcessingStep2 => 'Building the agreement structure…';

  @override
  String get aiProcessingStep3 => 'Determining required terms…';

  @override
  String get aiProcessingStep4 => 'Almost ready…';

  @override
  String get aiProcessingServerError => 'Couldn\'t reach the server.';

  @override
  String get aiProcessingNoMatchTitle =>
      'Couldn\'t determine the agreement type';

  @override
  String get aiProcessingNoMatchBody =>
      'Describe what you\'d like to agree on in more detail — for example, \"selling a car\" or \"renting out an apartment\".';

  @override
  String get aiProcessingEditRequest => 'Edit request';

  @override
  String extractionFilledSummary(int count, String plural, String remaining) {
    return 'Automatically filled in $count $plural — you won\'t need to type them in. $remaining';
  }

  @override
  String get extractionPluralFieldOne => 'field';

  @override
  String get extractionPluralFieldFew => 'fields';

  @override
  String get extractionPluralFieldMany => 'fields';

  @override
  String get extractionRemainingUnknown =>
      'Just a couple more details to clarify.';

  @override
  String get extractionRemainingNone =>
      'No more questions left — the agreement is almost ready.';

  @override
  String get extractionRemainingOne => 'Just one detail left.';

  @override
  String extractionRemainingFew(int n) {
    return 'Only $n details left.';
  }

  @override
  String extractionRemainingMany(int n) {
    return '$n details left.';
  }

  @override
  String extractionAndMore(int count) {
    return 'and $count more…';
  }

  @override
  String get extractionContinue => 'Continue';

  @override
  String get profileHistoryEntry => 'Deal history';

  @override
  String get historyTitle => 'Deal history';

  @override
  String get historySearchHint => 'Search by title or party';

  @override
  String get historyFilterAll => 'All';

  @override
  String get historyFilterDraft => 'Drafts';

  @override
  String get historyFilterSigned => 'Signed';

  @override
  String get historyFilterWaiting => 'Awaiting signature';

  @override
  String get historyFilterCancelled => 'Cancelled';

  @override
  String get historyEmptyTitle => 'You don\'t have any agreements yet';

  @override
  String get historyEmptyMessage =>
      'Create your first agreement and it will show up here.';

  @override
  String get historyCreateDeal => 'Create agreement';

  @override
  String get historyNothingFoundMessage =>
      'Nothing matches this filter or search.';

  @override
  String get historyStatusDraft => 'Draft';

  @override
  String get historyStatusWaitingSecondParty => 'Awaiting the other party';

  @override
  String get historyStatusWaitingYourSignature => 'Awaiting your signature';

  @override
  String get historyStatusSigned => 'Signed';

  @override
  String get historyStatusCancelled => 'Cancelled';

  @override
  String get historyDetailCreatedLabel => 'Created';

  @override
  String get historyDetailUpdatedLabel => 'Updated';

  @override
  String get historyDetailSecondPartyLabel => 'Other party';

  @override
  String get historyDetailStatusLabel => 'Status';

  @override
  String get historyDetailContinue => 'Continue filling in';

  @override
  String get historyDetailOpenDocument => 'Open agreement';

  @override
  String get historyDetailCancelDeal => 'Cancel deal';

  @override
  String get historyDetailCancelConfirmTitle => 'Cancel this deal?';

  @override
  String get historyDetailCancelConfirmBody =>
      'This can\'t be undone. The agreement will be marked as cancelled.';

  @override
  String get historyDetailCancelConfirmButton => 'Cancel deal';

  @override
  String get historyDetailCancelFailed => 'Couldn\'t cancel the deal.';

  @override
  String get historyDetailCancelledNotice => 'This deal has been cancelled.';

  @override
  String get explanationDeposit =>
      'If there\'s a deposit, we\'ll add that term to the agreement. That way both parties know exactly how much and when to pay.';

  @override
  String get explanationPaymentMethod =>
      'We need to specify the payment method. It helps describe the payment procedure precisely in the agreement.';

  @override
  String get explanationBankDetails =>
      'We ask for the bank details so the money goes to the right account. They\'ll be listed in the payment section.';

  @override
  String get explanationInterestRate =>
      'We\'re clarifying the rate so both parties understand the terms the same way. It\'ll be written into the agreement along with the amount.';

  @override
  String get explanationSalary =>
      'We ask for the payment amount so it\'s recorded in writing. This sum will be stated in the agreement.';

  @override
  String get explanationPrice =>
      'We state the price so both parties understand the deal\'s value the same way. This amount will go into the agreement.';

  @override
  String get explanationTransferDate =>
      'We need the transfer date. It\'ll be stated in the agreement and helps avoid disputes about timing.';

  @override
  String get explanationRepaymentDate =>
      'We\'re clarifying when the money should be repaid. This date will be stated in the agreement so both parties know the deadline.';

  @override
  String get explanationStartDate =>
      'We ask for the start date so it\'s recorded in writing. The agreement takes effect from that day.';

  @override
  String get explanationDuration =>
      'We\'re clarifying the term so both parties understand how long the agreement applies. These dates will be stated in the agreement.';

  @override
  String get explanationGenericDate =>
      'We ask for the date so it\'s recorded in writing. That way both parties know when things should happen.';

  @override
  String get explanationTransferPlace =>
      'This place will be stated in the agreement as the transfer location, so both parties know where the deal takes place.';

  @override
  String get explanationAddress =>
      'The address is needed so the agreement clearly identifies which object it\'s about. It\'ll be included in the subject description.';

  @override
  String get explanationVehicleIds =>
      'This number helps the agreement precisely identify which vehicle is meant, so it can\'t be confused with any other.';

  @override
  String get explanationVehicleMakeModel =>
      'We ask this to describe the vehicle precisely in the agreement. Both parties will know exactly what\'s being sold.';

  @override
  String get explanationPropertyDetails =>
      'These details describe the object in the agreement, so it\'s clear exactly what\'s being transferred with no ambiguity.';

  @override
  String get explanationPersonalInfo =>
      'We ask this so the agreement precisely states who\'s party to the deal. The agreement can\'t be signed without this information.';

  @override
  String get explanationJobTitle =>
      'We\'re clarifying the job title so the agreement is clear about what work you\'ve agreed on. It\'ll be stated in the duties section.';

  @override
  String get explanationContacts =>
      'Contact details are needed so the parties can reach each other. They\'ll be listed at the end of the agreement.';

  @override
  String get explanationExtraTerms =>
      'You can note any additional arrangements here - they\'ll be included in the agreement too.';

  @override
  String get explanationFallback =>
      'We ask this so the agreement accurately reflects what you\'ve agreed on. Your answer will go into the matching clause of the document.';

  @override
  String get interviewAck1 => 'Great.';

  @override
  String get interviewAck2 => 'Very good.';

  @override
  String get interviewAck3 => 'Got it.';

  @override
  String get interviewAck4 => 'Perfect.';

  @override
  String get interviewAck5 => 'Understood.';

  @override
  String get interviewAck6 => 'Noted.';

  @override
  String get interviewAck7 => 'Thanks.';

  @override
  String get interviewAck8 => 'Good.';

  @override
  String get interviewAck9 => 'Recorded.';

  @override
  String get interviewAck10 => 'Clear now.';

  @override
  String get interviewAck11 => 'Marking that down.';

  @override
  String get interviewAck12 => 'Adding it to the agreement.';

  @override
  String get interviewDocAck1 => 'The document really helped.';

  @override
  String get interviewDocAck2 => 'That cuts the form-filling a lot.';

  @override
  String get interviewDocAck3 => 'Almost everything\'s ready.';

  @override
  String get interviewThinking1 => 'Adding this to the agreement…';

  @override
  String get interviewThinking2 => 'Updating the agreement…';

  @override
  String get interviewThinking3 => 'Checking the details…';

  @override
  String get interviewThinking4 => 'Analyzing…';

  @override
  String get interviewThinking5 => 'Cross-checking the information…';

  @override
  String get interviewThinking6 => 'Entering it into the document…';

  @override
  String get interviewScanning1 => 'Reading the document…';

  @override
  String get interviewScanning2 => 'Recognizing the data…';

  @override
  String get interviewScanning3 => 'Cross-checking the details…';

  @override
  String get interviewScanning4 => 'Filling in the agreement…';

  @override
  String get interviewGenerationStep1 => 'Checking the data';

  @override
  String get interviewGenerationStep2 => 'Analyzing the terms';

  @override
  String get interviewGenerationStep3 => 'Drafting the agreement';

  @override
  String get interviewGenerationStep4 => 'Checking legal consistency';

  @override
  String get interviewGenerationStep5 => 'Document ready';

  @override
  String get interviewProgressFirstQuestion => 'Preparing the agreement…';

  @override
  String get interviewProgressLastQuestion => 'One last small detail left.';

  @override
  String get interviewProgressTwoLeft1 => 'Two more details.';

  @override
  String get interviewProgressTwoLeft2 =>
      'Almost there — a couple more details.';

  @override
  String get interviewProgressFewLeft1 => 'Just a little left.';

  @override
  String get interviewProgressFewLeft2 => 'Most of it is already done.';

  @override
  String get interviewProgressFewLeft3 => 'Great progress.';

  @override
  String get interviewProgressEarly1 => 'Moving on…';

  @override
  String get interviewProgressEarly2 => 'Going great so far.';

  @override
  String get interviewProgressMid1 => 'The agreement is taking shape…';

  @override
  String get interviewProgressMid2 => 'Good pace.';

  @override
  String get interviewProgressLate1 => 'Almost done…';

  @override
  String get interviewProgressLate2 => 'We\'re nearly finished.';

  @override
  String interviewGreetingTitle(String templateTitle) {
    return 'I\'ll help prepare\n\"$templateTitle\"';
  }

  @override
  String get interviewGreetingBody =>
      'I\'ll fill in everything I can automatically, and only ask about what\'s missing.';

  @override
  String get interviewCelebration1 => 'Great! Document recognized';

  @override
  String get interviewCelebration2 => 'Done! I\'ve read it all';

  @override
  String get interviewCelebration3 => 'Nice — the document helped';

  @override
  String get interviewCelebration4 => 'Great choice';

  @override
  String get interviewCompletionFallback1 =>
      'Everything needed is already gathered.';

  @override
  String get interviewCompletionFallback2 => 'Ready to generate the agreement.';

  @override
  String get interviewCompletionFallback3 => 'Great work.';

  @override
  String get interviewCompletionFallback4 => 'Done — just needs confirming.';

  @override
  String get interviewConfidenceReliable => 'Reliably recognized';

  @override
  String get interviewConfidenceCheck => 'Please double-check this value';

  @override
  String get interviewRemainingAlmostDone => '≈ Almost done';

  @override
  String get interviewRemainingLastOne => '≈ One last detail left';

  @override
  String interviewRemainingCountFew(int remaining) {
    return '≈ $remaining small details left';
  }

  @override
  String interviewRemainingCountMany(int remaining) {
    return '≈ $remaining small details left';
  }

  @override
  String interviewTimeSavedSeconds(int seconds) {
    return 'You saved about $seconds seconds.';
  }

  @override
  String interviewTimeSavedMinutes(int minutes) {
    return 'You saved about $minutes min.';
  }

  @override
  String get interviewDocHintVehicle =>
      'If it\'s easier, you can also upload a photo of the vehicle registration - I\'ll fill this and the rest in automatically.';

  @override
  String get interviewDocHintRealEstate =>
      'If you have the documents handy, you can just upload a photo of them - it\'s faster.';

  @override
  String get interviewDocHintBusiness =>
      'If it\'s easier, you can upload a photo of the document instead of typing it in.';

  @override
  String get interviewDocHintEmployment =>
      'If it\'s easier, you can upload a photo of the document instead of typing it in.';

  @override
  String get interviewDocHintBank =>
      'If it\'s easier, you can upload a photo of the details instead of typing them in.';

  @override
  String get interviewDocHintInheritance =>
      'If it\'s easier, you can upload a photo of the certificate instead of typing it in.';

  @override
  String get interviewDocHintCourt =>
      'If it\'s easier, you can upload a photo of the court ruling instead of typing it in.';

  @override
  String get interviewDocHintLoan =>
      'If it\'s easier, you can upload a photo of the agreement instead of typing it in.';

  @override
  String get interviewDocHintService =>
      'If it\'s easier, you can upload a photo of the document instead of typing it in.';
}
