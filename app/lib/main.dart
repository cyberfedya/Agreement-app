import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/network/api_client.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/services/api_service.dart';
import 'package:app/core/services/tts_service.dart';
import 'package:app/core/storage/local_storage.dart';
import 'package:app/core/storage/shared_preferences_local_storage.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/agreement/data/agreement_repository.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/deal/data/deal_repository.dart';
import 'package:app/features/documents/data/document_repository.dart';
import 'package:app/features/documents/providers/document_upload_provider.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/features/questionnaire/data/questionnaire_repository.dart';
import 'package:app/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:app/features/templates/data/template_repository.dart';
import 'package:app/features/templates/providers/template_detail_provider.dart';
import 'package:app/features/templates/providers/templates_list_provider.dart';

void main() {
  runApp(const EasyAgreeApp());
}

class EasyAgreeApp extends StatelessWidget {
  /// [apiClient] is exposed for tests: real HTTP I/O only works when the
  /// client is constructed inside `tester.runAsync`, before the widget tree
  /// (and its lazy DI graph) is pumped.
  const EasyAgreeApp({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => apiClient ?? ApiClient()),
        Provider<ApiService>(create: (ctx) => ApiService(ctx.read<ApiClient>())),
        Provider<LocalStorage>(create: (_) => SharedPreferencesLocalStorage()),
        Provider<ProfileRepository>(
          create: (ctx) => ApiProfileRepository(ctx.read<ApiService>(), ctx.read<LocalStorage>()),
        ),
        Provider<TemplateRepository>(create: (ctx) => ApiTemplateRepository(ctx.read<ApiService>())),
        Provider<QuestionnaireRepository>(
          create: (ctx) => ApiQuestionnaireRepository(ctx.read<ApiService>()),
        ),
        Provider<AgreementRepository>(create: (ctx) => ApiAgreementRepository(ctx.read<ApiService>())),
        Provider<DealRepository>(
          create: (ctx) => ApiDealRepository(ctx.read<ApiService>(), ctx.read<ProfileRepository>()),
        ),
        Provider<DocumentRepository>(create: (ctx) => ApiDocumentRepository(ctx.read<ApiService>())),
        Provider<TtsService>(create: (_) => TtsService(), dispose: (_, tts) => tts.dispose()),
        ChangeNotifierProvider(create: (ctx) => TemplatesListProvider(ctx.read<TemplateRepository>())),
        ChangeNotifierProvider(
          create: (ctx) => TemplateDetailProvider(
            ctx.read<TemplateRepository>(),
            ctx.read<QuestionnaireRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => QuestionnaireProvider(ctx.read<QuestionnaireRepository>(), ctx.read<DocumentRepository>()),
        ),
        ChangeNotifierProvider(create: (ctx) => AgreementProvider(ctx.read<AgreementRepository>())),
        ChangeNotifierProvider(create: (ctx) => DocumentUploadProvider(ctx.read<DocumentRepository>())),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
