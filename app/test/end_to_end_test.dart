import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/core/services/tts_service.dart';
import 'package:app/core/storage/local_storage.dart';
import 'package:app/features/onboarding/onboarding_page.dart';
import 'package:app/features/agreement/data/agreement_repository.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/features/agreement/domain/deal_invite.dart';
import 'package:app/features/agreement/presentation/agreement_page.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/ai_processing/presentation/ai_processing_page.dart';
import 'package:app/features/deal/data/deal_repository.dart';
import 'package:app/features/deal/domain/deal.dart';
import 'package:app/features/deal/domain/deal_history.dart';
import 'package:app/features/documents/data/document_repository.dart';
import 'package:app/features/documents/domain/document_verification.dart';
import 'package:app/features/documents/domain/interview_preview.dart';
import 'package:app/features/documents/domain/required_document.dart';
import 'package:app/features/documents/domain/uploaded_document.dart';
import 'package:app/features/documents/providers/document_upload_provider.dart';
import 'package:app/features/home/presentation/home_page.dart';
import 'package:app/features/questionnaire/data/questionnaire_repository.dart';
import 'package:app/features/questionnaire/domain/deal_review.dart';
import 'package:app/features/questionnaire/domain/interview_step.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/features/questionnaire/presentation/pages/questionnaire_page.dart';
import 'package:app/features/questionnaire/presentation/widgets/answer_composer.dart';
import 'package:app/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:app/features/templates/data/template_repository.dart';
import 'package:app/features/templates/domain/template.dart';
import 'package:app/features/templates/presentation/templates_list_page.dart';
import 'package:app/features/templates/providers/template_detail_provider.dart';
import 'package:app/features/templates/providers/templates_list_provider.dart';
import 'package:app/shared/models/result.dart';
class FakeTemplateRepository implements TemplateRepository {
  FakeTemplateRepository({this.listResult, this.detailResult});

  Result<List<TemplateSummary>>? listResult;
  Result<TemplateDetail>? detailResult;

  @override
  Future<Result<List<TemplateSummary>>> getTemplates() async =>
      listResult ?? const Success<List<TemplateSummary>>([]);

  @override
  Future<Result<TemplateDetail>> getTemplate(String key) async =>
      detailResult ?? const Failure('not found');
}

/// Scripts the Interview Planner's turn-by-turn responses. [steps] is
/// consumed in order (one per `nextQuestion` call); the last entry repeats
/// if there are more calls than scripted steps.
class FakeQuestionnaireRepository implements QuestionnaireRepository {
  FakeQuestionnaireRepository(this.steps, {this.allFieldsResult});

  final List<Result<InterviewStep>> steps;
  final Result<List<Question>>? allFieldsResult;
  int _callIndex = 0;

  @override
  Future<Result<List<Question>>> getQuestions(String templateKey) async =>
      allFieldsResult ?? const Success<List<Question>>([]);

  @override
  Future<Result<List<Question>>> getQuestionsForDeal(String dealId) async =>
      allFieldsResult ?? const Success<List<Question>>([]);

  @override
  Future<Result<InterviewStep>> nextQuestion(String dealId, {int? fieldId, String? answer, String? question}) async {
    final step = steps[_callIndex.clamp(0, steps.length - 1)];
    if (_callIndex < steps.length - 1) _callIndex++;
    return step;
  }

  @override
  Future<Result<void>> dismissDocumentSuggestion(String dealId, String documentType) async => const Success(null);

  /// A minimal but honest stand-in: every scripted field the interview
  /// walked through is reported back as "manual" - good enough for the
  /// review screen to render without asserting on its exact grouping.
  @override
  Future<Result<DealReview>> getReview(String dealId) async => Success(
    DealReview(
      autoFilled: const [],
      manual: [
        for (final question in _questions)
          DealReviewField(
            fieldId: question.fieldId,
            label: question.fieldName,
            value: 'answered',
            source: 'manual',
            confidence: 1,
            status: 'CONFIRMED',
            reason: 'Recorded interview answer',
          ),
      ],
      corrected: const [],
      missing: const [],
      skipped: const [],
      fieldStates: const [],
      workflowStatus: 'READY_TO_GENERATE',
      workflowReason: 'All mandatory terms have trusted values.',
    ),
  );
}

class FakeAgreementRepository implements AgreementRepository {
  FakeAgreementRepository(this.result);

  final Result<Agreement> result;

  @override
  Future<Result<Agreement>> generate(String dealId, Map<int, String> answers) async => result;

  @override
  Future<Result<Agreement>> getByDealId(String dealId) async => result;

  @override
  Future<Result<void>> signAsSecondParty(String dealId, String fullName) async => const Success(null);

  @override
  Future<Result<void>> signAsFirstParty(String dealId, String fullName) async => const Success(null);

  @override
  Future<Result<DealInvite>> getInvite(String dealId) async => const Failure('not used in these tests');

  @override
  Future<Result<void>> acceptInvite(String dealId, String profileId) async => const Success(null);

  @override
  Future<Result<void>> declineInvite(String dealId, {String? reason, String? profileId}) async =>
      const Success(null);

  @override
  Future<Result<void>> proposeFieldChange(
    String dealId, {
    required int fieldId,
    required String proposedValue,
    String? reason,
    String? profileId,
  }) async => const Success(null);

  @override
  Future<Result<void>> requestClarification(String dealId, {required String message, String? profileId}) async =>
      const Success(null);
}

/// In-memory [LocalStorage] so tests never touch SharedPreferences.
/// Starts with onboarding already seen - the first-launch intro has its
/// own test value, but every flow test starts from the login screen.
class FakeLocalStorage implements LocalStorage {
  final Map<String, String> _values = {OnboardingPage.seenKey: 'true'};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

/// Defaults to a matched deal for both entry points, mirroring the happy
/// path; individual tests override to script no-match or failure.
class FakeDealRepository implements DealRepository {
  FakeDealRepository({this.createFromTextResult, this.createFromTemplateResult});

  Result<Deal?>? createFromTextResult;
  Result<Deal>? createFromTemplateResult;

  @override
  Future<Result<Deal?>> createFromText(String text) async => createFromTextResult ?? const Success(_matchedDeal);

  @override
  Future<Result<Deal>> createFromTemplate(String templateKey) async =>
      createFromTemplateResult ?? const Success(_matchedDeal);

  @override
  Future<Result<DealHistoryPage>> listDeals({int page = 1, int pageSize = 20}) async =>
      const Success(DealHistoryPage(items: [], totalCount: 0, page: 1, pageSize: 20));

  @override
  Future<Result<void>> cancelDeal(String dealId) async => const Success(null);
}

/// Defaults to "nothing to suggest" so the creation flow goes straight to
/// the interview, matching the pre-document-upload happy path.
class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository({this.requiredDocumentsResult});

  Result<List<RequiredDocument>>? requiredDocumentsResult;

  @override
  Future<Result<List<RequiredDocument>>> getRequiredDocuments(String dealId) async =>
      requiredDocumentsResult ?? const Success<List<RequiredDocument>>([]);

  @override
  Future<Result<List<UploadedDocument>>> getDealDocuments(String dealId) async =>
      const Success<List<UploadedDocument>>([]);

  @override
  Future<Result<List<UploadedDocument>>> upload(
    String dealId,
    List<(String fileName, String contentType, List<int> bytes)> files,
  ) async => const Success<List<UploadedDocument>>([]);

  @override
  Future<Result<void>> delete(String dealId, String documentId) async => const Success(null);

  @override
  Future<Result<void>> updateField(String dealId, String documentId, String key, String value) async =>
      const Success(null);

  @override
  Future<Result<InterviewPreview>> getInterviewPreview(String dealId) async =>
      const Success(InterviewPreview(totalAskableFields: 0, estimatedRemainingQuestions: 0));

  @override
  Future<Result<DocumentVerification>> verifyDocument(String dealId) async =>
      const Success(DocumentVerification(conflicts: []));
}

const _matchedDeal = Deal(
  id: 'deal-1',
  templateKey: 'vehicle_sale_agreement',
  templateTitle: 'Договор купли-продажи автотранспортного средства',
  status: DealStatus.draft,
);

const _fullNameQuestion = Question(fieldId: 1, fieldName: 'Full name', required: true, type: 'text');
const _optionalNoteQuestion = Question(fieldId: 2, fieldName: 'Optional note', required: false, type: 'text');
const _questions = [_fullNameQuestion, _optionalNoteQuestion];

/// A two-turn interview (ask field 1, then field 2, then ready) — the
/// scripted shape most tests exercise.
List<Result<InterviewStep>> _twoQuestionSteps() => [
  const Success(InterviewStep(readyToGenerate: false, question: _fullNameQuestion)),
  const Success(InterviewStep(readyToGenerate: false, question: _optionalNoteQuestion)),
  const Success(InterviewStep(readyToGenerate: true)),
];

Widget buildTestApp({
  TemplateRepository? templateRepository,
  QuestionnaireRepository? questionnaireRepository,
  AgreementRepository? agreementRepository,
  DealRepository? dealRepository,
  DocumentRepository? documentRepository,
  String initialRoute = AppRoutes.splash,
}) {
  final templates = templateRepository ?? FakeTemplateRepository();
  final questionnaire =
      questionnaireRepository ?? FakeQuestionnaireRepository(_twoQuestionSteps(), allFieldsResult: const Success(_questions));
  final agreements = agreementRepository ??
      FakeAgreementRepository(Success(Agreement(key: 'deal-1', html: '<p>x</p>', generatedAt: DateTime(2026))));
  final documents = documentRepository ?? FakeDocumentRepository();

  return MultiProvider(
    providers: [
      Provider<TemplateRepository>.value(value: templates),
      Provider<DealRepository>.value(value: dealRepository ?? FakeDealRepository()),
      Provider<DocumentRepository>.value(value: documents),
      Provider<LocalStorage>(create: (_) => FakeLocalStorage()),
      Provider<TtsService>(create: (_) => TtsService()),
      ChangeNotifierProvider(create: (_) => TemplatesListProvider(templates)),
      ChangeNotifierProvider(create: (_) => TemplateDetailProvider(templates, questionnaire)),
      ChangeNotifierProvider(create: (_) => QuestionnaireProvider(questionnaire, documents)),
      ChangeNotifierProvider(create: (_) => AgreementProvider(agreements)),
      ChangeNotifierProvider(create: (_) => DocumentUploadProvider(documents)),
    ],
    child: MaterialApp(
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
    ),
  );
}

/// Pumps past Splash's fixed 700ms auto-navigate timer, landing on the
/// demo MyID login screen.
///
/// Deliberately not using `initialRoute: AppRoutes.home` as a shortcut:
/// Flutter's default initial-route handling splits any multi-segment path
/// into a full route stack (["/", "/home"]), which builds SplashPage in the
/// background too — its timer then fires and clobbers later navigation.
Future<void> _skipSplash(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

/// Completes the demo MyID login (fixed 1400ms simulated verification),
/// landing on Home.
Future<void> _completeLogin(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Продолжить с MyID'));
  await tester.pump(const Duration(milliseconds: 1400));
  await tester.pumpAndSettle();
}

/// Home -> AI Processing: types a request and taps create, then pumps past
/// the fixed ~2400ms analysis animation.
Future<void> _submitRequest(WidgetTester tester, [String text = 'Я хочу продать свою машину']) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Создать договор'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 2650));
  await tester.pumpAndSettle();
}

/// The composer's answer field (idle mode).
Finder _answerField() => find.descendant(of: find.byType(AnswerComposer), matching: find.byType(TextField));

/// Types [text] and sends it, then pumps through the thinking beat
/// (Motion.thinkingMin) and the next question's entrance.
Future<void> _answer(WidgetTester tester, String text) async {
  await tester.enterText(_answerField(), text);
  // Settle first: the send button scales in via AnimatedSwitcher and is
  // not hit-testable mid-transition.
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Отправить'));
  await tester.pumpAndSettle();
}

/// The interview always offers the optional final document check first
/// when no document was uploaded during it (`FakeDocumentRepository`
/// always reports zero) - skip it to reach the ordinary review/generate
/// screen the way most tests still expect.
Future<void> _skipDocumentVerification(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Пропустить'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('happy path: splash -> login -> home -> AI match -> interview -> agreement', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        agreementRepository: FakeAgreementRepository(
          Success(Agreement(key: 'deal-1', html: '<p>Generated agreement body</p>', generatedAt: DateTime(2026))),
        ),
      ),
    );
    await _skipSplash(tester);
    await _completeLogin(tester);
    expect(find.byType(HomePage), findsOneWidget);

    await _submitRequest(tester);

    // Straight to the interview for the matched deal — the Agreements
    // template picker is not part of the creation flow. The greeting beat
    // (min 1800ms) has already been pumped through by pumpAndSettle.
    expect(find.byType(QuestionnairePage), findsOneWidget);
    expect(find.byType(TemplatesListPage), findsNothing);
    expect(find.text(_matchedDeal.templateTitle), findsOneWidget);
    expect(find.byType(AnswerComposer), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    // No questionnaire numbering anywhere in the conversational interview.
    expect(find.textContaining('Вопрос'), findsNothing);

    // The send button only materializes once there is something to send.
    expect(find.byTooltip('Отправить'), findsNothing);
    await tester.enterText(_answerField(), 'Aliyev Vali');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Отправить'), findsOneWidget);

    await tester.tap(find.byTooltip('Отправить'));
    await tester.pumpAndSettle();

    expect(find.text('Optional note'), findsOneWidget);

    await _answer(tester, 'A quick note');

    // No document was uploaded during the interview - the optional final
    // check offers to verify one before the review phase.
    await _skipDocumentVerification(tester);

    // Planner says it has enough — the review phase offers to generate.
    expect(find.text('Договор готов к созданию'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Создать договор'));
    // Bounded pumps instead of pumpAndSettle: the generation checklist is
    // finite, but the agreement page it lands on hosts an endless
    // waiting-for-signature pulse that would never settle.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AgreementPage), findsOneWidget);
    // The QR/status header pushes the document preview below the sliver's
    // build cache, so scroll to it rather than assume it's built.
    await tester.scrollUntilVisible(find.byType(Html), 300, scrollable: find.byType(Scrollable).first);
    expect(find.byType(Html), findsOneWidget);
  });

  testWidgets('AI no-match stays on the processing screen and offers to rephrase', (tester) async {
    await tester.pumpWidget(
      buildTestApp(dealRepository: FakeDealRepository(createFromTextResult: const Success(null))),
    );
    await _skipSplash(tester);
    await _completeLogin(tester);

    await _submitRequest(tester, 'абракадабра');

    expect(find.byType(AiProcessingPage), findsOneWidget);
    expect(find.byType(TemplatesListPage), findsNothing);
    expect(find.text('Не удалось определить тип договора'), findsOneWidget);

    // "Изменить запрос" returns to Home with the text preserved.
    await tester.tap(find.widgetWithText(FilledButton, 'Изменить запрос'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('абракадабра'), findsOneWidget);
  });

  testWidgets('network failure stays on the processing screen with retry', (tester) async {
    final dealRepository = FakeDealRepository(
      createFromTextResult: const Failure('Could not reach the server. Check your connection.'),
    );
    await tester.pumpWidget(buildTestApp(dealRepository: dealRepository));
    await _skipSplash(tester);
    await _completeLogin(tester);

    await _submitRequest(tester);

    expect(find.byType(AiProcessingPage), findsOneWidget);
    expect(find.byType(TemplatesListPage), findsNothing);
    expect(find.text('Could not reach the server. Check your connection.'), findsOneWidget);

    // Retry succeeds once the network is back.
    dealRepository.createFromTextResult = const Success(_matchedDeal);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 2650));
    await tester.pumpAndSettle();

    expect(find.byType(QuestionnairePage), findsOneWidget);
  });

  testWidgets('generate failure surfaces a snackbar and stays on the questionnaire', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        agreementRepository: FakeAgreementRepository(
          const Failure('Please answer all required questions before generating.'),
        ),
      ),
    );
    await _skipSplash(tester);
    await _completeLogin(tester);
    await _submitRequest(tester);

    await _answer(tester, 'Aliyev Vali');
    await _answer(tester, 'A quick note');
    await _skipDocumentVerification(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Создать договор'));
    await tester.pumpAndSettle();

    expect(find.byType(QuestionnairePage), findsOneWidget);
    expect(find.byType(AgreementPage), findsNothing);
    expect(find.text('Please answer all required questions before generating.'), findsOneWidget);
  });

  testWidgets('answers auto-save when navigating back and forth', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await _skipSplash(tester);
    await _completeLogin(tester);
    await _submitRequest(tester);

    await _answer(tester, 'Saved answer');
    expect(find.text('Optional note'), findsOneWidget);

    await tester.tap(find.byTooltip('Предыдущий шаг'));
    await tester.pumpAndSettle();

    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Saved answer'), findsOneWidget);
  });
}
