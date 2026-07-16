import 'dart:math';

import 'package:app/features/questionnaire/presentation/document_hint_matcher.dart';
import 'package:app/l10n/app_localizations.dart';

/// Coarse "how close to done" bucket - deliberately just a handful of
/// steps, not a percentage, so the phrase pool can stay meaningful at
/// each one. Ordered roughly by how close to finishing the interview is.
enum ProgressTier { firstQuestion, lastQuestion, twoLeft, fewLeft, early, mid, late }

/// The assistant's conversational voice: every phrase the interview shows
/// that is not backend content comes from here, so the tone stays in one
/// place. Pools rotate randomly but never repeat the same phrase twice in
/// a row - a repeated "Отлично." is what makes bots feel like bots.
///
/// Every method takes the current [AppLocalizations] explicitly rather
/// than storing it, since this class is constructed once per interview
/// session (to keep [_lastByPool]'s anti-repeat memory) while the locale
/// can still change underneath it.
class InterviewScript {
  InterviewScript({Random? random}) : _random = random ?? Random();

  final Random _random;
  final Map<String, String> _lastByPool = {};

  String _pick(String poolKey, List<String> pool) {
    if (pool.length == 1) return pool.first;
    final last = _lastByPool[poolKey];
    String choice;
    do {
      choice = pool[_random.nextInt(pool.length)];
    } while (choice == last);
    _lastByPool[poolKey] = choice;
    return choice;
  }

  /// Short emotional beat shown above the next question after an answer.
  String acknowledgment(AppLocalizations l10n) => _pick('ack', [
    l10n.interviewAck1,
    l10n.interviewAck2,
    l10n.interviewAck3,
    l10n.interviewAck4,
    l10n.interviewAck5,
    l10n.interviewAck6,
    l10n.interviewAck7,
    l10n.interviewAck8,
    l10n.interviewAck9,
    l10n.interviewAck10,
    l10n.interviewAck11,
    l10n.interviewAck12,
  ]);

  /// The beat shown for the *first* question after a document upload just
  /// filled several fields - names the document explicitly instead of a
  /// generic reaction, so the assistant sounds like it noticed the help.
  String documentFollowUpAcknowledgment(AppLocalizations l10n) =>
      _pick('ack-doc', [l10n.interviewDocAck1, l10n.interviewDocAck2, l10n.interviewDocAck3]);

  /// Shown for [Motion.thinkingMin]+ while the answer is being processed.
  String thinking(AppLocalizations l10n) => _pick('thinking', [
    l10n.interviewThinking1,
    l10n.interviewThinking2,
    l10n.interviewThinking3,
    l10n.interviewThinking4,
    l10n.interviewThinking5,
    l10n.interviewThinking6,
  ]);

  /// Rotating status while an uploaded document is being read by the AI.
  List<String> scanningSteps(AppLocalizations l10n) => [
    l10n.interviewScanning1,
    l10n.interviewScanning2,
    l10n.interviewScanning3,
    l10n.interviewScanning4,
  ];

  /// Checklist steps for the premium pre-generation sequence
  /// ([GenerationSequenceView]) - purely decorative pacing around the real
  /// `generate` call, never a substitute for its result.
  List<String> generationSteps(AppLocalizations l10n) => [
    l10n.interviewGenerationStep1,
    l10n.interviewGenerationStep2,
    l10n.interviewGenerationStep3,
    l10n.interviewGenerationStep4,
    l10n.interviewGenerationStep5,
  ];

  /// Which bucket the interview is in right now - pure classification of
  /// backend-supplied numbers (or their absence), no invented thresholds
  /// beyond what the previous deterministic status already used.
  static ProgressTier progressTier({required bool firstQuestion, int? remaining, required int answeredCount}) {
    if (firstQuestion) return ProgressTier.firstQuestion;
    if (remaining != null) {
      if (remaining <= 1) return ProgressTier.lastQuestion;
      if (remaining == 2) return ProgressTier.twoLeft;
      if (remaining <= 4) return ProgressTier.fewLeft;
    }
    if (answeredCount <= 2) return ProgressTier.early;
    if (answeredCount <= 4) return ProgressTier.mid;
    return ProgressTier.late;
  }

  /// A phrase for [tier]. Callers must cache the result per-tier
  /// themselves (re-picking only when the tier actually changes) - called
  /// fresh on every rebuild, this would flicker between synonyms for the
  /// same state instead of reading as steady progress.
  String progressPhrase(ProgressTier tier, AppLocalizations l10n) => switch (tier) {
    ProgressTier.firstQuestion => l10n.interviewProgressFirstQuestion,
    // A one-off, deliberately singular moment - no rotation, so it never
    // competes with itself for "this is almost over" gravity.
    ProgressTier.lastQuestion => l10n.interviewProgressLastQuestion,
    ProgressTier.twoLeft => _pick('progress-2', [l10n.interviewProgressTwoLeft1, l10n.interviewProgressTwoLeft2]),
    ProgressTier.fewLeft => _pick('progress-few', [
      l10n.interviewProgressFewLeft1,
      l10n.interviewProgressFewLeft2,
      l10n.interviewProgressFewLeft3,
    ]),
    ProgressTier.early => _pick('progress-early', [l10n.interviewProgressEarly1, l10n.interviewProgressEarly2]),
    ProgressTier.mid => _pick('progress-mid', [l10n.interviewProgressMid1, l10n.interviewProgressMid2]),
    ProgressTier.late => _pick('progress-late', [l10n.interviewProgressLate1, l10n.interviewProgressLate2]),
  };

  /// Opening beat: what the assistant says the moment the interview opens,
  /// while the planner decides the first step. Never a question.
  String greetingTitle(String templateTitle, AppLocalizations l10n) => l10n.interviewGreetingTitle(templateTitle);

  String greetingBody(AppLocalizations l10n) => l10n.interviewGreetingBody;

  /// Celebration headline after a successful document scan.
  String celebrationTitle(AppLocalizations l10n) => _pick('celebrate', [
    l10n.interviewCelebration1,
    l10n.interviewCelebration2,
    l10n.interviewCelebration3,
    l10n.interviewCelebration4,
  ]);

  /// Fallback line for the review screen's hero card, used only when the
  /// backend didn't send a `closingMessage` for this deal - the backend's
  /// own wording always wins when present, this is decoration for the gap.
  String completionFallback(AppLocalizations l10n) => _pick('completion', [
    l10n.interviewCompletionFallback1,
    l10n.interviewCompletionFallback2,
    l10n.interviewCompletionFallback3,
    l10n.interviewCompletionFallback4,
  ]);

  /// Confidence threshold above which an OCR-extracted value is presented
  /// as trustworthy rather than "please double-check" - purely a label
  /// over the backend-supplied confidence number, never a decision about
  /// whether the value is used.
  static const double reliableConfidenceThreshold = 0.85;

  /// Label for an OCR-extracted field's [confidence] (0..1, from the
  /// backend). Presentation only - the number itself is never computed
  /// here, just described.
  static String confidenceLabel(double confidence, AppLocalizations l10n) =>
      confidence >= reliableConfidenceThreshold ? l10n.interviewConfidenceReliable : l10n.interviewConfidenceCheck;

  /// A soft, conversational read of the backend's honest
  /// remaining-questions count ("≈ Осталось 3 небольших уточнения")
  /// instead of a cold "Question 5 of 17" - formatting of the backend's
  /// own number only, never a new estimate anything else depends on.
  static String remainingEstimate(int remaining, AppLocalizations l10n) {
    if (remaining <= 0) return l10n.interviewRemainingAlmostDone;
    if (remaining == 1) return l10n.interviewRemainingLastOne;
    return _isFewForm(remaining) ? l10n.interviewRemainingCountFew(remaining) : l10n.interviewRemainingCountMany(remaining);
  }

  static bool _isFewForm(int n) {
    final mod10 = n % 10, mod100 = n % 100;
    return mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14);
  }

  /// "Вы сэкономили ~N сек/мин" for the celebration screen, from the
  /// number of fields OCR actually filled - same 15s/field assumption as
  /// [remainingEstimate], stated as an approximation, not a guarantee.
  static String timeSavedLine(int fieldsFilled, AppLocalizations l10n) {
    if (fieldsFilled <= 0) return '';
    final seconds = fieldsFilled * 15;
    return seconds < 60 ? l10n.interviewTimeSavedSeconds(seconds) : l10n.interviewTimeSavedMinutes((seconds / 60).round());
  }

  /// Spoken-only addition appended after the question text when
  /// [DocumentHintCard] is showing - never written into the question
  /// itself, since that text is echoed back to the backend to classify
  /// the answer. Purely an audio nudge; the assistant then goes straight
  /// back to waiting for the user's answer.
  static String documentHintSuffix(DocumentHintCategory category, AppLocalizations l10n) => switch (category) {
    DocumentHintCategory.vehicle => l10n.interviewDocHintVehicle,
    DocumentHintCategory.realEstate => l10n.interviewDocHintRealEstate,
    DocumentHintCategory.business => l10n.interviewDocHintBusiness,
    DocumentHintCategory.employment => l10n.interviewDocHintEmployment,
    DocumentHintCategory.bank => l10n.interviewDocHintBank,
    DocumentHintCategory.inheritance => l10n.interviewDocHintInheritance,
    DocumentHintCategory.court => l10n.interviewDocHintCourt,
    DocumentHintCategory.loan => l10n.interviewDocHintLoan,
    DocumentHintCategory.service => l10n.interviewDocHintService,
  };
}
