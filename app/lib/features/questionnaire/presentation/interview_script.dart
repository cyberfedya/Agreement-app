import 'dart:math';

import 'package:app/features/questionnaire/presentation/document_hint_matcher.dart';

/// Coarse "how close to done" bucket - deliberately just a handful of
/// steps, not a percentage, so the phrase pool can stay meaningful at
/// each one. Ordered roughly by how close to finishing the interview is.
enum ProgressTier { firstQuestion, lastQuestion, twoLeft, fewLeft, early, mid, late }

/// The assistant's conversational voice: every phrase the interview shows
/// that is not backend content comes from here, so the tone stays in one
/// place. Pools rotate randomly but never repeat the same phrase twice in
/// a row - a repeated "Отлично." is what makes bots feel like bots.
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
  String acknowledgment() => _pick('ack', const [
    'Отлично.',
    'Очень хорошо.',
    'Понятно.',
    'Прекрасно.',
    'Понял.',
    'Принято.',
    'Спасибо.',
    'Хорошо.',
    'Записал.',
    'Теперь всё понятно.',
    'Отмечаю это.',
    'Добавляю в договор.',
  ]);

  /// The beat shown for the *first* question after a document upload just
  /// filled several fields - names the document explicitly instead of a
  /// generic reaction, so the assistant sounds like it noticed the help.
  String documentFollowUpAcknowledgment() => _pick('ack-doc', const [
    'Документ действительно помог.',
    'Это сильно сокращает заполнение.',
    'Почти всё готово.',
  ]);

  /// Shown for [Motion.thinkingMin]+ while the answer is being processed.
  String thinking() => _pick('thinking', const [
    'Добавляю это в договор…',
    'Обновляю договор…',
    'Проверяю данные…',
    'Анализирую…',
    'Сверяю информацию…',
    'Вношу в документ…',
  ]);

  /// Rotating status while an uploaded document is being read by the AI.
  List<String> get scanningSteps => const [
    'Читаю документ…',
    'Распознаю данные…',
    'Сверяю реквизиты…',
    'Заполняю договор…',
  ];

  /// Checklist steps for the premium pre-generation sequence
  /// ([GenerationSequenceView]) - purely decorative pacing around the real
  /// `generate` call, never a substitute for its result.
  List<String> get generationSteps => const [
    'Проверяю данные',
    'Анализирую условия',
    'Формирую договор',
    'Проверяю юридическую целостность',
    'Документ готов',
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
  String progressPhrase(ProgressTier tier) => switch (tier) {
    ProgressTier.firstQuestion => 'Готовим договор…',
    // A one-off, deliberately singular moment - no rotation, so it never
    // competes with itself for "this is almost over" gravity.
    ProgressTier.lastQuestion => 'Осталось последнее небольшое уточнение.',
    ProgressTier.twoLeft => _pick('progress-2', const ['Ещё две детали.', 'Почти у цели — ещё пара деталей.']),
    ProgressTier.fewLeft => _pick('progress-few', const [
      'Осталось совсем немного.',
      'Уже большая часть готова.',
      'Отличный прогресс.',
    ]),
    ProgressTier.early => _pick('progress-early', const ['Продолжаем…', 'Всё идёт отлично.']),
    ProgressTier.mid => _pick('progress-mid', const ['Договор растёт…', 'Хороший темп.']),
    ProgressTier.late => _pick('progress-late', const ['Почти готово…', 'Мы почти закончили.']),
  };

  /// Opening beat: what the assistant says the moment the interview opens,
  /// while the planner decides the first step. Never a question.
  String greetingTitle(String templateTitle) => 'Помогу подготовить\n«$templateTitle»';

  String get greetingBody =>
      'Я заполню всё, что смогу, автоматически — '
      'и спрошу только то, чего не хватает.';

  /// Celebration headline after a successful document scan.
  String celebrationTitle() => _pick('celebrate', const [
    'Отлично! Документ распознан',
    'Готово! Я всё прочитал',
    'Супер — документ помог',
    'Отличное решение',
  ]);

  /// Fallback line for the review screen's hero card, used only when the
  /// backend didn't send a `closingMessage` for this deal - the backend's
  /// own wording always wins when present, this is decoration for the gap.
  String completionFallback() => _pick('completion', const [
    'Всё необходимое уже собрано.',
    'Можно формировать договор.',
    'Отличная работа.',
    'Готово — осталось только подтвердить.',
  ]);

  /// Confidence threshold above which an OCR-extracted value is presented
  /// as trustworthy rather than "please double-check" - purely a label
  /// over the backend-supplied confidence number, never a decision about
  /// whether the value is used.
  static const double reliableConfidenceThreshold = 0.85;

  /// Label for an OCR-extracted field's [confidence] (0..1, from the
  /// backend). Presentation only - the number itself is never computed
  /// here, just described.
  static String confidenceLabel(double confidence) =>
      confidence >= reliableConfidenceThreshold ? 'Надёжно распознано' : 'Проверьте это значение';

  /// A soft, conversational read of the backend's honest
  /// remaining-questions count ("≈ Осталось 3 небольших уточнения")
  /// instead of a cold "Question 5 of 17" - formatting of the backend's
  /// own number only, never a new estimate anything else depends on.
  static String remainingEstimate(int remaining) {
    if (remaining <= 0) return '≈ Почти готово';
    if (remaining == 1) return '≈ Осталось последнее уточнение';
    return '≈ Осталось $remaining ${_smallDetailsWord(remaining)}';
  }

  static String _smallDetailsWord(int n) {
    final mod10 = n % 10, mod100 = n % 100;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'небольших уточнения';
    return 'небольших уточнений';
  }

  /// "Вы сэкономили ~N сек/мин" for the celebration screen, from the
  /// number of fields OCR actually filled - same 15s/field assumption as
  /// [remainingEstimate], stated as an approximation, not a guarantee.
  static String timeSavedLine(int fieldsFilled) {
    if (fieldsFilled <= 0) return '';
    final seconds = fieldsFilled * 15;
    return seconds < 60
        ? 'Вы сэкономили примерно $seconds секунд.'
        : 'Вы сэкономили примерно ${(seconds / 60).round()} мин.';
  }

  /// Spoken-only addition appended after the question text when
  /// [DocumentHintCard] is showing - never written into the question
  /// itself, since that text is echoed back to the backend to classify
  /// the answer. Purely an audio nudge; the assistant then goes straight
  /// back to waiting for the user's answer.
  static String documentHintSuffix(DocumentHintCategory category) => switch (category) {
    DocumentHintCategory.vehicle =>
      'Если удобнее, можете также загрузить фотографию техпаспорта — '
          'я заполню это и остальные данные автоматически.',
    DocumentHintCategory.realEstate =>
      'Если документы рядом, можете просто загрузить их фотографию — это быстрее.',
    DocumentHintCategory.business =>
      'Если удобнее, можете загрузить фотографию документа вместо ввода вручную.',
    DocumentHintCategory.employment =>
      'Если удобнее, можете загрузить фотографию документа вместо ввода вручную.',
    DocumentHintCategory.bank =>
      'Если удобнее, можете загрузить фотографию реквизитов вместо ввода вручную.',
  };
}
