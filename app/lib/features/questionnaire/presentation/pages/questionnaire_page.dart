import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/services/tts_service.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/documents/presentation/uploaded_documents_sheet.dart';
import 'package:app/features/documents/providers/document_upload_provider.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/features/questionnaire/presentation/document_hint_matcher.dart';
import 'package:app/features/questionnaire/presentation/interview_script.dart';
import 'package:app/features/questionnaire/presentation/question_explanations.dart';
import 'package:app/features/questionnaire/presentation/widgets/agreement_preview_sheet.dart';
import 'package:app/features/questionnaire/presentation/widgets/answer_composer.dart';
import 'package:app/features/questionnaire/presentation/widgets/assistant_question_view.dart';
import 'package:app/features/questionnaire/presentation/widgets/conversation_recap.dart';
import 'package:app/features/questionnaire/presentation/widgets/document_hint_card.dart';
import 'package:app/features/questionnaire/presentation/widgets/document_invite_view.dart';
import 'package:app/features/questionnaire/presentation/widgets/document_verification_view.dart';
import 'package:app/features/questionnaire/presentation/widgets/document_scanning_view.dart';
import 'package:app/features/questionnaire/presentation/widgets/extraction_celebration_view.dart';
import 'package:app/features/questionnaire/presentation/widgets/generation_sequence_view.dart';
import 'package:app/features/questionnaire/presentation/widgets/greeting_view.dart';
import 'package:app/features/questionnaire/presentation/widgets/interview_header.dart';
import 'package:app/features/questionnaire/presentation/widgets/interview_stage_banner.dart';
import 'package:app/features/questionnaire/presentation/widgets/review_view.dart';
import 'package:app/features/questionnaire/presentation/widgets/thinking_indicator.dart';
import 'package:app/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:app/shared/animation/entrance.dart';
import 'package:app/shared/utils/image_format.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// The Agreement Interview, redesigned as a conversation with an AI legal
/// assistant rather than a questionnaire:
///
///   greeting -> (document invite -> scanning -> celebration) ->
///   questions with thinking beats -> review -> generate
///
/// There is deliberately no "Вопрос N" anywhere. Progress is expressed as
/// how ready the agreement is, and the live document (header chip) grows
/// after every answer. All backend contracts are unchanged - this is a
/// pure presentation/state redesign over the same Interview Planner.
class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key, required this.dealId, required this.templateTitle});

  final String dealId;
  final String templateTitle;

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final TextEditingController _controller = TextEditingController();
  final InterviewScript _script = InterviewScript();
  final ImagePicker _picker = ImagePicker();

  /// Micro-emotion shown above the current question; null before the first
  /// answer (nothing to acknowledge yet).
  String? _acknowledgment;

  /// Non-null while the post-answer "Обновляю договор…" beat is showing.
  String? _thinkingLabel;

  /// The answer the user just sent, echoed back as "✓ …" during the
  /// thinking beat - a quiet receipt that the assistant heard exactly
  /// what was said, before the conversation moves on.
  String? _submittedEcho;

  /// True while an upload+OCR round-trip runs (invite or paperclip path).
  bool _uploadingDocument = false;

  /// True between a successful OCR and the user tapping "Продолжить" on
  /// the celebration screen.
  bool _celebrating = false;
  String _celebrationTitle = '';

  /// Greeting stays up at least this long even when the backend answers
  /// faster, so the intro actually registers as a sentence, not a flash.
  bool _greetingHoldDone = false;
  bool _interviewStarted = false;

  bool _closingSpoken = false;
  String? _lastSpokenQuestionText;
  int? _controllerBoundToFieldId;

  /// True from the moment "Создать договор" is tapped until navigation to
  /// the agreement screen (or a failure reverts to the review).
  bool _generating = false;

  /// Cached so the progress phrase only re-rolls when the underlying
  /// [ProgressTier] actually changes, not on every rebuild - see
  /// [InterviewScript.progressPhrase].
  ProgressTier? _progressTierCache;
  String _progressPhraseCache = '';

  /// Decorative fallback for the review hero when the backend didn't send
  /// a `closingMessage` for this deal - picked once when the interview
  /// first becomes ready, not re-rolled on every review-screen rebuild.
  String? _completionFallback;

  /// Whether the final optional document check has been decided for this
  /// interview - computed once, the moment the interview first becomes
  /// ready, from whether any document was uploaded during it. Not
  /// re-evaluated afterwards, so uploading a document *during* the check
  /// itself doesn't retroactively hide it.
  bool _documentVerificationDecided = false;
  bool _showDocumentVerification = false;

  /// Minimum number of answered questions between two document-upload
  /// nudges for the *same* category. 1, not higher: the vehicle interview
  /// deliberately asks its document-fillable identifiers back to back
  /// (engine number -> body number -> plate), and the upload card must
  /// appear on each of them - suppressing the 2nd and 3rd made the offer
  /// look like it applied only to the engine number.
  static const int _hintCooldownQuestions = 1;

  /// [QuestionnaireProvider.answers] length at which each category was
  /// last shown, so re-showing it can be rate-limited independently per
  /// topic (a vehicle nudge doesn't suppress a real-estate one).
  final Map<DocumentHintCategory, int> _hintShownAtAnswerCount = {};

  /// The nudge currently offered for [QuestionnaireProvider.currentQuestion],
  /// if any - re-evaluated whenever the field changes, clearable early via
  /// its own dismiss button without affecting the cooldown above (it was
  /// already shown once, so it stays cooled down either way).
  DocumentHintCategory? _activeHint;

  QuestionnaireProvider? _provider;
  TtsService? _tts;

  @override
  void initState() {
    super.initState();
    final provider = context.read<QuestionnaireProvider>();
    final documentUploadProvider = context.read<DocumentUploadProvider>();
    Future.microtask(() {
      documentUploadProvider.attachDeal(widget.dealId);
      return provider.start(widget.dealId);
    });
    // Long enough to actually read the two-line greeting (title + promise),
    // not just glimpse it - 1.8s proved too short in real use.
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) setState(() => _greetingHoldDone = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tts = context.read<TtsService>();
    final provider = context.read<QuestionnaireProvider>();
    if (!identical(_provider, provider)) {
      _provider?.removeListener(_onProviderChanged);
      _provider = provider..addListener(_onProviderChanged);
    }
  }

  @override
  void dispose() {
    _tts?.stop();
    _provider?.removeListener(_onProviderChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Keeps the composer in sync with whichever question is current -
  /// prefilled when going back to an already-answered one, empty for a
  /// fresh one - and reads each new question aloud.
  void _onProviderChanged() {
    if (_provider?.readyToGenerate ?? false) {
      _completionFallback ??= _script.completionFallback();
      final closing = _provider?.closingMessage;
      if (!_closingSpoken && closing != null) {
        _closingSpoken = true;
        _tts?.speak(closing);
      }
      return;
    }

    final field = _provider?.currentQuestion;
    if (field == null) return;

    final sameField = field.fieldId == _controllerBoundToFieldId;
    final textChanged = field.fieldName != _lastSpokenQuestionText;
    if (sameField && !textChanged) return;

    _controllerBoundToFieldId = field.fieldId;
    _lastSpokenQuestionText = field.fieldName;

    // A repeated question (side remark handled, interview didn't move on)
    // keeps the same fieldId but comes back with new text woven in -
    // clear the box instead of reusing the goBack()-style answer prefill.
    final text = sameField ? '' : _provider!.answerFor(field.fieldId);
    _controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

    _activeHint = _evaluateDocumentHint(field);
    final hint = _activeHint;
    if (hint != null) {
      _hintShownAtAnswerCount[hint] = _provider!.answers.length;
      _tts?.speak('${field.fieldName} ${InterviewScript.documentHintSuffix(hint)}');
    } else {
      _tts?.speak(field.fieldName);
    }
  }

  /// Whether to show [DocumentHintCard] for [field]: it must look
  /// document-friendly, the user must not already have a processed
  /// document on file (they either skipped the initial upload or it
  /// didn't cover this), and this topic must not have been nudged in the
  /// last [_hintCooldownQuestions] answers - never every question.
  DocumentHintCategory? _evaluateDocumentHint(Question field) {
    final uploads = context.read<DocumentUploadProvider>();
    if (uploads.uploadedDocuments.any((d) => d.isProcessed)) return null;

    final category = DocumentHintMatcher.categoryFor(field.fieldName);
    if (category == null) return null;

    final answeredCount = _provider!.answers.length;
    final lastShownAt = _hintShownAtAnswerCount[category];
    if (lastShownAt != null && answeredCount - lastShownAt < _hintCooldownQuestions) return null;

    return category;
  }

  void _dismissHint() => setState(() => _activeHint = null);

  /// Answer -> short thinking beat (never shorter than [Motion.thinkingMin])
  /// -> next question arrives under a fresh acknowledgment.
  Future<void> _submitAnswer(String text) async {
    final provider = context.read<QuestionnaireProvider>();
    if (provider.isLoading || text.trim().isEmpty) return;

    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {
      _thinkingLabel = _script.thinking();
      _submittedEcho = text.trim();
    });

    await Future.wait([provider.submitAnswer(text.trim()), Future<void>.delayed(Motion.thinkingMin)]);
    if (!mounted) return;

    setState(() {
      _thinkingLabel = null;
      _acknowledgment = _script.acknowledgment();
    });
  }

  // --- Document upload (invite screen + composer paperclip) ---

  Future<void> _pickAndUpload(ImageSource source) async {
    final files = source == ImageSource.camera
        ? await _picker.pickImage(source: ImageSource.camera, imageQuality: 85).then((f) => f == null ? <XFile>[] : [f])
        : await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty || !mounted) return;

    final entries = <(String, String, List<int>)>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      // Never trust the OS-reported mime type (frequently null on Android)
      // or assume jpeg - sniff the real format from the bytes, the same
      // way the backend will, so the two can never disagree about what
      // was actually sent.
      final contentType = sniffImageContentType(bytes);
      if (contentType == null) continue;
      entries.add((normalizedFileName(file.name, contentType), contentType, bytes));
    }
    if (!mounted) return;

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось распознать формат фото. Попробуйте JPEG, PNG или WebP.')),
      );
      return;
    }

    setState(() => _uploadingDocument = true);
    final uploadProvider = context.read<DocumentUploadProvider>();
    final questionnaire = context.read<QuestionnaireProvider>();
    final success = await uploadProvider.upload(entries);
    if (!mounted) return;

    if (success) {
      HapticFeedback.mediumImpact();
      // Refresh the backend's remaining-questions estimate so the
      // celebration line reflects what the upload just covered.
      unawaited(questionnaire.refreshDerivedState());
      setState(() {
        _uploadingDocument = false;
        _celebrating = true;
        _celebrationTitle = _script.celebrationTitle();
      });
    } else {
      setState(() => _uploadingDocument = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(uploadProvider.errorMessage ?? 'Не удалось загрузить документ.')));
    }
  }

  /// "Продолжить" on the celebration screen: let the planner skip
  /// everything the upload filled. The next question's acknowledgment
  /// names the document explicitly instead of a generic reaction, so the
  /// assistant sounds like it noticed the help it just got.
  Future<void> _continueAfterCelebration() async {
    final questionnaire = context.read<QuestionnaireProvider>();
    final uploads = context.read<DocumentUploadProvider>();
    HapticFeedback.selectionClick();
    uploads.clearMismatchWarnings();
    setState(() {
      _celebrating = false;
      _acknowledgment = _script.documentFollowUpAcknowledgment();
    });
    await questionnaire.resumeAfterDocumentUpload();
  }

  Future<void> _attachFromComposer() async {
    final documentCount = context.read<DocumentUploadProvider>().uploadedDocuments.length;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Insets.x8),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Камера'),
                onTap: () => Navigator.pop(sheetContext, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Галерея'),
                onTap: () => Navigator.pop(sheetContext, 'gallery'),
              ),
              if (documentCount > 0)
                ListTile(
                  leading: const Icon(Icons.folder_copy_outlined),
                  title: Text('Мои документы ($documentCount)'),
                  subtitle: const Text('Посмотреть, исправить или удалить'),
                  onTap: () => Navigator.pop(sheetContext, 'documents'),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;

    switch (choice) {
      case 'camera':
        await _pickAndUpload(ImageSource.camera);
      case 'gallery':
        await _pickAndUpload(ImageSource.gallery);
      case 'documents':
        final questionnaire = context.read<QuestionnaireProvider>();
        await UploadedDocumentsSheet.show(
          context,
          // Fixing/removing a document changes what the backend can fill -
          // refresh progress/review so the interview reflects it.
          onChanged: () => unawaited(questionnaire.refreshDerivedState()),
        );
    }
  }

  void _showWhySheet(String question) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.xl)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Insets.x24, Insets.x24, Insets.x24, Insets.x32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Зачем это нужно?', style: theme.textTheme.titleLarge),
              const SizedBox(height: Insets.x12),
              Text(
                QuestionExplanations.forQuestion(question),
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tap "Создать договор" -> premium checklist sequence, paced by
  /// [Motion.generationStep] per step, running in parallel with the real
  /// `generate` call - whichever takes longer wins, so a fast backend
  /// still shows the full sequence and a slow one is never masked by a
  /// fake progress bar that lies about being done.
  Future<void> _generate() async {
    if (_generating) return;
    final questionnaire = context.read<QuestionnaireProvider>();
    final agreementProvider = context.read<AgreementProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    HapticFeedback.mediumImpact();
    setState(() => _generating = true);

    final minSequenceDuration = Motion.generationStep * (_script.generationSteps.length - 1);
    final results = await Future.wait([
      agreementProvider.generate(widget.dealId, questionnaire.answers),
      Future<void>.delayed(minSequenceDuration),
    ]);
    if (!mounted) return;

    final success = results[0] as bool;
    if (success) {
      navigator.pushNamed(AppRoutes.agreement);
    } else {
      setState(() => _generating = false);
      messenger.showSnackBar(
        SnackBar(content: Text(agreementProvider.errorMessage ?? 'Не удалось создать договор.')),
      );
    }
  }

  // --- Progress (backend-computed, presentation scaling only) ---

  /// Renders `GET /interview-preview`'s numbers as a 0..1 bar. The only
  /// local math is a small visual floor so the bar is never empty and a
  /// pin to 1 once the backend declares the interview ready.
  double _progress(QuestionnaireProvider p) {
    if (p.readyToGenerate) return 1;
    final preview = p.preview;
    if (preview == null || preview.totalAskableFields == 0) return 0.08;
    final covered = preview.totalAskableFields - preview.estimatedRemainingQuestions;
    return (0.08 + 0.92 * covered / preview.totalAskableFields).clamp(0.0, 1.0);
  }

  /// Progress phrase, re-rolled only when the underlying [ProgressTier]
  /// changes - reading it every rebuild without caching would pick a new
  /// synonym on every frame for the exact same state, which reads as
  /// noise rather than a calm, steady assistant.
  String _statusText(QuestionnaireProvider provider) {
    if (provider.readyToGenerate) return 'Договор готов к созданию';
    final tier = InterviewScript.progressTier(
      firstQuestion: provider.answers.isEmpty,
      remaining: provider.preview?.estimatedRemainingQuestions,
      answeredCount: provider.answers.length,
    );
    if (tier != _progressTierCache) {
      _progressTierCache = tier;
      _progressPhraseCache = _script.progressPhrase(tier);
    }
    return _progressPhraseCache;
  }

  /// Labels of every field already answered, in the order they were
  /// answered - [QuestionnaireProvider.answers] is a `Map` populated in
  /// insertion order, and [QuestionnaireProvider.allFields] supplies the
  /// human labels. Pure formatting of two already-fetched backend lists,
  /// nothing computed.
  List<String> _answeredLabels(QuestionnaireProvider provider) {
    final labelsById = {for (final q in provider.allFields) q.fieldId: q.fieldName};
    return [
      for (final fieldId in provider.answers.keys) ?labelsById[fieldId],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<QuestionnaireProvider, DocumentUploadProvider>(
          builder: (context, provider, uploads, _) {
            final hasContent = provider.currentQuestion != null ||
                provider.readyToGenerate ||
                provider.documentSuggestion != null ||
                provider.errorMessage != null;
            final showGreeting = !_interviewStarted && (!_greetingHoldDone || !hasContent);
            if (!showGreeting && hasContent) _interviewStarted = true;

            final Widget content;
            if (_generating) {
              content = GenerationSequenceView(key: const ValueKey('generating'), steps: _script.generationSteps);
            } else if (_uploadingDocument) {
              content = DocumentScanningView(key: const ValueKey('scanning'), steps: _script.scanningSteps);
            } else if (_celebrating) {
              content = ExtractionCelebrationView(
                key: const ValueKey('celebration'),
                title: _celebrationTitle,
                documents: uploads.lastUploadBatch,
                remainingQuestions: provider.preview?.estimatedRemainingQuestions,
                warnings: uploads.pendingMismatchWarnings,
                onContinue: _continueAfterCelebration,
              );
            } else if (showGreeting) {
              content = GreetingView(
                key: const ValueKey('greeting'),
                title: _script.greetingTitle(widget.templateTitle),
                body: _script.greetingBody,
              );
            } else if (provider.errorMessage != null && provider.currentQuestion == null && !provider.readyToGenerate) {
              content = AppErrorView(
                key: const ValueKey('error'),
                message: provider.errorMessage!,
                onRetry: () => provider.start(widget.dealId),
              );
            } else if (provider.documentSuggestion != null) {
              content = DocumentInviteView(
                key: const ValueKey('invite'),
                suggestion: provider.documentSuggestion!,
                onCamera: () => _pickAndUpload(ImageSource.camera),
                onGallery: () => _pickAndUpload(ImageSource.gallery),
                onSkip: () => provider.dismissDocumentSuggestion(),
              );
            } else if (provider.readyToGenerate) {
              if (!_documentVerificationDecided) {
                _documentVerificationDecided = true;
                _showDocumentVerification = uploads.uploadedDocuments.isEmpty;
              }
              content = _showDocumentVerification
                  ? DocumentVerificationView(
                      key: const ValueKey('doc-verification'),
                      dealId: widget.dealId,
                      onFinished: () => setState(() => _showDocumentVerification = false),
                    )
                  : _withHeader(
                      provider,
                      ReviewView(templateTitle: widget.templateTitle, fallbackMessage: _completionFallback),
                    );
            } else if (provider.currentQuestion != null) {
              content = _questionPhase(provider);
            } else {
              // Between phases (e.g. right after dismissing the document
              // invite) while the planner decides the next step.
              content = const Center(
                key: ValueKey('inter-step'),
                child: ThinkingIndicator(label: 'Готовлю следующий шаг…'),
              );
            }

            return CenteredContent(
              child: AnimatedSwitcher(
                duration: Motion.slow,
                switchInCurve: Motion.curve,
                switchOutCurve: Motion.curve,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: content,
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Consumer<QuestionnaireProvider>(
        builder: (context, provider, _) {
          if (!provider.readyToGenerate ||
              _celebrating ||
              _uploadingDocument ||
              _generating ||
              _showDocumentVerification) {
            return const SizedBox.shrink();
          }
          return BottomActionBar(
            child: Consumer<AgreementProvider>(
              builder: (context, agreementProvider, _) => PrimaryButton(
                label: 'Создать договор',
                loading: agreementProvider.isLoading,
                onPressed: _generate,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Header (status + live progress + document chip) over any phase that
  /// is part of the "agreement is being built" narrative. Keyed by phase,
  /// not by question - the header must stay mounted across questions so
  /// its progress bar sweeps forward instead of restarting from zero.
  Widget _withHeader(QuestionnaireProvider provider, Widget child) {
    return Column(
      key: ValueKey(provider.readyToGenerate ? 'phase-review' : 'phase-question'),
      children: [
        InterviewHeader(
          title: widget.templateTitle,
          status: _statusText(provider),
          estimate: provider.readyToGenerate || provider.preview?.estimatedRemainingQuestions == null
              ? null
              : InterviewScript.remainingEstimate(provider.preview!.estimatedRemainingQuestions),
          progress: _progress(provider),
          onOpenDocument: () => AgreementPreviewSheet.show(context, title: widget.templateTitle),
          onBack: provider.canGoBack ? provider.goBack : () => Navigator.of(context).maybePop(),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _questionPhase(QuestionnaireProvider provider) {
    final field = provider.currentQuestion!;
    final thinking = _thinkingLabel != null;

    return _withHeader(
      provider,
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Insets.x24, Insets.x8, Insets.x24, 0),
            child: InterviewStageBanner(stage: provider.currentStage),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.normal,
              switchInCurve: Motion.curve,
              switchOutCurve: Motion.curve,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: thinking
                  ? Center(
                      key: const ValueKey('thinking'),
                      child: _AnswerEchoWithThinking(echo: _submittedEcho, label: _thinkingLabel!),
                    )
                  : AssistantQuestionView(
                      key: ValueKey('q-${field.fieldId}-${field.fieldName}'),
                      question: field,
                      acknowledgment: _acknowledgment,
                      onSpeak: () => _tts?.speak(
                        _activeHint == null
                            ? field.fieldName
                            : '${field.fieldName} ${InterviewScript.documentHintSuffix(_activeHint!)}',
                      ),
                      onWhy: () => _showWhySheet(field.fieldName),
                      recap: provider.answers.isEmpty
                          ? null
                          : ConversationRecap(answeredLabels: _answeredLabels(provider)),
                      documentHint: _activeHint == null
                          ? null
                          : DocumentHintCard(
                              key: ValueKey('hint-${_activeHint!.name}'),
                              onUpload: _attachFromComposer,
                              onDismiss: _dismissHint,
                            ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Insets.x20, 0, Insets.x20, Insets.x16),
            child: AnswerComposer(
              controller: _controller,
              enabled: !provider.isLoading && !thinking,
              onSubmit: _submitAnswer,
              onAttach: _uploadingDocument ? null : _attachFromComposer,
            ),
          ).animateEntrance(delay: const Duration(milliseconds: 150)),
        ],
      ),
    );
  }
}

/// The post-answer beat: the user's own words echoed back with a check
/// ("✓ Завтра") above the thinking line - a quiet receipt, then the
/// conversation moves on. Long answers are clipped, not scrolled.
class _AnswerEchoWithThinking extends StatelessWidget {
  const _AnswerEchoWithThinking({required this.echo, required this.label});

  final String? echo;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.x32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (echo != null && echo!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: Corners.x2lRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: Insets.x8),
                  Flexible(
                    child: Text(
                      echo!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.x16),
          ],
          ThinkingIndicator(label: label),
        ],
      ),
    );
  }
}
