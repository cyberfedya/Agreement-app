import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/widgets/app_search_bar.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/agreement/data/agreement_repository.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/features/agreement/presentation/agreement_page.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/home/presentation/home_page.dart';
import 'package:app/features/questionnaire/data/questionnaire_repository.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/features/questionnaire/presentation/pages/questionnaire_page.dart';
import 'package:app/features/questionnaire/presentation/widgets/question_card.dart';
import 'package:app/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:app/features/templates/data/template_repository.dart';
import 'package:app/features/templates/domain/template.dart';
import 'package:app/features/templates/presentation/template_detail_page.dart';
import 'package:app/features/templates/presentation/templates_list_page.dart';
import 'package:app/features/templates/presentation/widgets/agreement_card.dart';
import 'package:app/features/templates/providers/template_detail_provider.dart';
import 'package:app/features/templates/providers/templates_list_provider.dart';
import 'package:app/shared/models/result.dart';

/// Drives the full navigation flow (splash -> home -> list -> detail ->
/// questionnaire -> preview) through the real pages, providers, and router,
/// against fake repositories standing in for the network layer.
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

class FakeQuestionnaireRepository implements QuestionnaireRepository {
  FakeQuestionnaireRepository(this.result);

  final Result<List<Question>> result;

  @override
  Future<Result<List<Question>>> getQuestions(String templateKey) async => result;
}

class FakeAgreementRepository implements AgreementRepository {
  FakeAgreementRepository(this.result);

  final Result<Agreement> result;

  @override
  Future<Result<Agreement>> generate(String templateKey, Map<int, String> answers) async => result;
}

const _template = TemplateSummary(
  key: 'test_key',
  domain: 'test_domain',
  title: 'Test Agreement Title',
  description: 'Test agreement description.',
);

const _templateDetail = TemplateDetail(
  key: 'test_key',
  domain: 'test_domain',
  title: 'Test Agreement Title',
  description: 'Test agreement description.',
  sourceUrl: 'https://example.com/doc/1',
);

const _questions = [
  Question(fieldId: 1, fieldName: 'Full name', required: true, type: 'text'),
  Question(fieldId: 2, fieldName: 'Optional note', required: false, type: 'text'),
];

Widget buildTestApp({
  required TemplateRepository templateRepository,
  required QuestionnaireRepository questionnaireRepository,
  required AgreementRepository agreementRepository,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => TemplatesListProvider(templateRepository)),
      ChangeNotifierProvider(
        create: (_) => TemplateDetailProvider(templateRepository, questionnaireRepository),
      ),
      ChangeNotifierProvider(create: (_) => QuestionnaireProvider(questionnaireRepository)),
      ChangeNotifierProvider(create: (_) => AgreementProvider(agreementRepository)),
    ],
    child: MaterialApp(
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );
}

/// Pumps past Splash's fixed 600ms auto-navigate timer.
///
/// Deliberately not using `initialRoute: AppRoutes.home` as a shortcut:
/// Flutter's default initial-route handling splits any multi-segment path
/// into a full route stack (["/", "/home"]), which builds SplashPage in the
/// background too — its timer then fires and clobbers later navigation.
Future<void> _skipSplash(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

/// Home -> Templates list (via the search shortcut near the top of Home).
Future<void> _openTemplatesList(WidgetTester tester) async {
  await tester.tap(find.byType(AppSearchBar).first);
  await tester.pumpAndSettle();
}

FilledButton _button(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

void main() {
  testWidgets('happy path: splash -> home -> list -> detail -> questionnaire -> preview', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        templateRepository: FakeTemplateRepository(
          listResult: const Success([_template]),
          detailResult: const Success(_templateDetail),
        ),
        questionnaireRepository: FakeQuestionnaireRepository(const Success(_questions)),
        agreementRepository: FakeAgreementRepository(
          Success(Agreement(key: 'test_key', html: '<p>Generated agreement body</p>', generatedAt: DateTime(2026))),
        ),
      ),
    );
    await _skipSplash(tester);
    expect(find.byType(HomePage), findsOneWidget);

    await _openTemplatesList(tester);
    expect(find.byType(TemplatesListPage), findsOneWidget);
    expect(find.text('Test Agreement Title'), findsOneWidget);

    await tester.tap(find.byType(AgreementCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(TemplateDetailPage), findsOneWidget);
    expect(find.text('Test agreement description.'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(QuestionnairePage), findsOneWidget);
    // One question per page (Typeform style).
    expect(find.byType(QuestionCard), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);

    // Next is disabled until the required question is answered.
    expect(_button(tester, 'Next').onPressed, isNull);

    final answerField = find.descendant(of: find.byType(QuestionCard), matching: find.byType(TextField));
    await tester.enterText(answerField, 'Aliyev Vali');
    await tester.pump();
    expect(_button(tester, 'Next').onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.text('Optional note'), findsOneWidget);
    expect(find.text('2 of 2'), findsOneWidget);

    // Second question is optional, so Generate is already enabled.
    expect(_button(tester, 'Generate').onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Generate'));
    await tester.pumpAndSettle();

    expect(find.byType(AgreementPage), findsOneWidget);
    expect(find.byType(Html), findsOneWidget);
  });

  testWidgets('templates list surfaces a friendly error with retry', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        templateRepository: FakeTemplateRepository(listResult: const Failure('Could not reach the server.')),
        questionnaireRepository: FakeQuestionnaireRepository(const Success(_questions)),
        agreementRepository: FakeAgreementRepository(
          Success(Agreement(key: 'k', html: '<p>x</p>', generatedAt: DateTime(2026))),
        ),
      ),
    );
    await _skipSplash(tester);

    await _openTemplatesList(tester);
    expect(find.byType(AppErrorView), findsWidgets);
    expect(find.text('Could not reach the server.'), findsWidgets);
    expect(find.text('Try again'), findsWidgets);
  });

  testWidgets('templates list shows an empty state when there are no templates', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        templateRepository: FakeTemplateRepository(listResult: const Success([])),
        questionnaireRepository: FakeQuestionnaireRepository(const Success(_questions)),
        agreementRepository: FakeAgreementRepository(
          Success(Agreement(key: 'k', html: '<p>x</p>', generatedAt: DateTime(2026))),
        ),
      ),
    );
    await _skipSplash(tester);

    await _openTemplatesList(tester);
    expect(find.byType(AppEmptyView), findsOneWidget);
  });

  testWidgets('generate failure surfaces a snackbar and stays on the questionnaire', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        templateRepository: FakeTemplateRepository(
          listResult: const Success([_template]),
          detailResult: const Success(_templateDetail),
        ),
        questionnaireRepository: FakeQuestionnaireRepository(const Success(_questions)),
        agreementRepository: FakeAgreementRepository(
          const Failure('Please answer all required questions before generating.'),
        ),
      ),
    );
    await _skipSplash(tester);

    await _openTemplatesList(tester);
    await tester.tap(find.byType(AgreementCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final answerField = find.descendant(of: find.byType(QuestionCard), matching: find.byType(TextField));
    await tester.enterText(answerField, 'Aliyev Vali');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Generate'));
    await tester.pumpAndSettle();

    expect(find.byType(QuestionnairePage), findsOneWidget);
    expect(find.byType(AgreementPage), findsNothing);
    expect(find.text('Please answer all required questions before generating.'), findsOneWidget);
  });

  testWidgets('answers auto-save when navigating back and forth', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        templateRepository: FakeTemplateRepository(
          listResult: const Success([_template]),
          detailResult: const Success(_templateDetail),
        ),
        questionnaireRepository: FakeQuestionnaireRepository(const Success(_questions)),
        agreementRepository: FakeAgreementRepository(
          Success(Agreement(key: 'k', html: '<p>x</p>', generatedAt: DateTime(2026))),
        ),
      ),
    );
    await _skipSplash(tester);
    await _openTemplatesList(tester);
    await tester.tap(find.byType(AgreementCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final answerField = find.descendant(of: find.byType(QuestionCard), matching: find.byType(TextField));
    await tester.enterText(answerField, 'Saved answer');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
    await tester.pumpAndSettle();

    expect(find.text('1 of 2'), findsOneWidget);
    expect(find.text('Saved answer'), findsOneWidget);
  });
}
