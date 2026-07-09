import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/services/tts_service.dart';
import 'package:app/features/agreement/data/agreement_repository.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/features/agreement/presentation/agreement_page.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/ai_processing/presentation/ai_processing_page.dart';
import 'package:app/features/deal/data/deal_repository.dart';
import 'package:app/features/deal/domain/deal.dart';
import 'package:app/features/home/presentation/home_page.dart';
import 'package:app/features/questionnaire/data/questionnaire_repository.dart';
import 'package:app/features/questionnaire/domain/interview_step.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/features/questionnaire/presentation/pages/questionnaire_page.dart';
import 'package:app/features/questionnaire/presentation/widgets/question_card.dart';
import 'package:app/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:app/features/templates/data/template_repository.dart';
import 'package:app/features/templates/domain/template.dart';
import 'package:app/features/templates/presentation/templates_list_page.dart';
import 'package:app/features/templates/providers/template_detail_provider.dart';
import 'package:app/features/templates/providers/templates_list_provider.dart';
import 'package:app/shared/models/result.dart';

/// Drives the full creation flow (splash -> login -> home -> AI match ->
/// interview -> generate -> agreement) through the real pages, providers,
/// and router, against fake repositories standing in for the network layer.
///
/// The backend contracts these fakes mimic were verified live against the
/// real .NET API + PostgreSQL. `flutter_test`'s fake-time zone cannot
/// service real socket I/O triggered from widget lifecycle callbacks, so a
/// real-network widget test isn't possible without `integration_test` on a
/// real device/browser.

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
  Future<Result<InterviewStep>> nextQuestion(String dealId, {int? fieldId, String? answer}) async {
    final step = steps[_callIndex.clamp(0, steps.length - 1)];
    if (_callIndex < steps.length - 1) _callIndex++;
    return step;
  }
}

class FakeAgreementRepository implements AgreementRepository {
  FakeAgreementRepository(this.result);

  final Result<Agreement> result;

  @override
  Future<Result<Agreement>> generate(String dealId, Map<int, String> answers) async => result;
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
  String initialRoute = AppRoutes.splash,
}) {
  final templates = templateRepository ?? FakeTemplateRepository();
  final questionnaire =
      questionnaireRepository ?? FakeQuestionnaireRepository(_twoQuestionSteps(), allFieldsResult: const Success(_questions));
  final agreements = agreementRepository ??
      FakeAgreementRepository(Success(Agreement(key: 'deal-1', html: '<p>x</p>', generatedAt: DateTime(2026))));

  return MultiProvider(
    providers: [
      Provider<TemplateRepository>.value(value: templates),
      Provider<DealRepository>.value(value: dealRepository ?? FakeDealRepository()),
      Provider<TtsService>(create: (_) => TtsService()),
      ChangeNotifierProvider(create: (_) => TemplatesListProvider(templates)),
      ChangeNotifierProvider(create: (_) => TemplateDetailProvider(templates, questionnaire)),
      ChangeNotifierProvider(create: (_) => QuestionnaireProvider(questionnaire)),
      ChangeNotifierProvider(create: (_) => AgreementProvider(agreements)),
    ],
    child: MaterialApp(
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
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

FilledButton _button(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

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
    // template picker is not part of the creation flow.
    expect(find.byType(QuestionnairePage), findsOneWidget);
    expect(find.byType(TemplatesListPage), findsNothing);
    expect(find.text(_matchedDeal.templateTitle), findsOneWidget);
    expect(find.byType(QuestionCard), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Вопрос 1'), findsOneWidget);

    // Next ("Далее") is disabled until the field has an answer.
    expect(_button(tester, 'Далее').onPressed, isNull);

    final answerField = find.descendant(of: find.byType(QuestionCard), matching: find.byType(TextField));
    await tester.enterText(answerField, 'Aliyev Vali');
    await tester.pump();
    expect(_button(tester, 'Далее').onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Далее'));
    await tester.pumpAndSettle();

    expect(find.text('Optional note'), findsOneWidget);
    expect(find.text('Вопрос 2'), findsOneWidget);

    await tester.enterText(answerField, 'A quick note');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Далее'));
    await tester.pumpAndSettle();

    // Planner says it has enough — submit button switches to Generate.
    expect(find.text('Готово к созданию'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Создать договор'));
    await tester.pumpAndSettle();

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
    await tester.tap(find.text('Try again'));
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

    final answerField = find.descendant(of: find.byType(QuestionCard), matching: find.byType(TextField));
    await tester.enterText(answerField, 'Aliyev Vali');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Далее'));
    await tester.pumpAndSettle();

    await tester.enterText(answerField, 'A quick note');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Далее'));
    await tester.pumpAndSettle();

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

    final answerField = find.descendant(of: find.byType(QuestionCard), matching: find.byType(TextField));
    await tester.enterText(answerField, 'Saved answer');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Далее'));
    await tester.pumpAndSettle();
    expect(find.text('Вопрос 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Предыдущий вопрос'));
    await tester.pumpAndSettle();

    expect(find.text('Вопрос 1'), findsOneWidget);
    expect(find.text('Saved answer'), findsOneWidget);
  });
}
