import 'package:flutter/material.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/agreement/presentation/agreement_completed_page.dart';
import 'package:app/features/agreement/presentation/agreement_page.dart';
import 'package:app/features/agreement/presentation/agreement_sign_page.dart';
import 'package:app/features/agreement/presentation/deal_invite_page.dart';
import 'package:app/features/ai_processing/presentation/ai_processing_page.dart';
import 'package:app/features/auth/presentation/auth_page.dart';
import 'package:app/features/deal/presentation/deal_history_detail_page.dart';
import 'package:app/features/deal/presentation/deal_history_page.dart';
import 'package:app/features/home/presentation/home_page.dart';
import 'package:app/features/onboarding/onboarding_page.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/features/profile/profile_page.dart';
import 'package:app/features/profile/settings_page.dart';
import 'package:app/features/questionnaire/presentation/pages/questionnaire_page.dart';
import 'package:app/features/qr/presentation/qr_page.dart';
import 'package:app/features/splash/splash_page.dart';
import 'package:app/features/templates/presentation/template_detail_page.dart';
import 'package:app/features/templates/presentation/templates_list_page.dart';

abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';

  /// Optional [TemplatesRouteArgs] argument.
  
  static const String templates = '/templates';

  /// Required `String` argument: template key.
  static const String templateDetail = '/templates/detail';

  /// Required [QuestionnaireRouteArgs] argument.
  static const String questionnaire = '/questionnaire';

  static const String agreement = '/agreement';

  /// Required `String` argument: the deal id from the scanned QR code.
  /// Invite metadata (type, roles, who invited) shown before any
  /// agreement HTML - accepting hands off to [agreementSign].
  static const String dealInvite = '/deal/invite';

  /// Required `String` argument: the scanned agreement key. Second-party
  /// document view + demo MyID identification + signing.
  static const String agreementSign = '/agreement/sign';

  static const String agreementCompleted = '/agreement/completed';

  static const String qrScan = '/qr-scan';

  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String dealHistory = '/deal/history';

  /// Required `String` argument: the deal id.
  static const String dealHistoryDetail = '/deal/history/detail';

  /// Required `String` argument: the user's free-form request text.
  static const String aiProcessing = '/ai-processing';
}

/// Arguments for [AppRoutes.templates].
class TemplatesRouteArgs {
  const TemplatesRouteArgs({this.category, this.query});

  final String? category;
  final String? query;
}

/// Arguments for [AppRoutes.questionnaire].
class QuestionnaireRouteArgs {
  const QuestionnaireRouteArgs({required this.dealId, required this.templateTitle});

  final String dealId;
  final String templateTitle;
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _fadeRoute(const SplashPage(), settings);
      case AppRoutes.onboarding:
        return _fadeRoute(const OnboardingPage(), settings);
      case AppRoutes.login:
        return _fadeRoute(const AuthPage(), settings);
      case AppRoutes.home:
        return _fadeRoute(const HomePage(), settings);
      case AppRoutes.templates:
        final args = settings.arguments as TemplatesRouteArgs?;
        return _fadeRoute(
          TemplatesListPage(initialCategory: args?.category, initialQuery: args?.query),
          settings,
        );
      case AppRoutes.templateDetail:
        return _fadeRoute(TemplateDetailPage(templateKey: settings.arguments as String), settings);
      case AppRoutes.questionnaire:
        final args = settings.arguments as QuestionnaireRouteArgs;
        return _fadeRoute(
          QuestionnairePage(dealId: args.dealId, templateTitle: args.templateTitle),
          settings,
        );
      case AppRoutes.agreement:
        return _fadeRoute(const AgreementPage(), settings);
      case AppRoutes.dealInvite:
        return _fadeRoute(DealInvitePage(dealId: settings.arguments as String), settings);
      case AppRoutes.agreementSign:
        return _fadeRoute(AgreementSignPage(agreementKey: settings.arguments as String), settings);
      case AppRoutes.agreementCompleted:
        return _fadeRoute(AgreementCompletedPage(isFirstParty: settings.arguments as bool? ?? true), settings);
      case AppRoutes.qrScan:
        return _fadeRoute(const QrPage(), settings);
      case AppRoutes.profile:
        return _fadeRoute(const ProfilePage(), settings);
      case AppRoutes.settings:
        return _fadeRoute(const SettingsPage(), settings);
      case AppRoutes.dealHistory:
        return _fadeRoute(const DealHistoryPage(), settings);
      case AppRoutes.dealHistoryDetail:
        return _fadeRoute(DealHistoryDetailPage(dealId: settings.arguments as String), settings);
      case AppRoutes.aiProcessing:
        return _fadeRoute(AiProcessingPage(requestText: settings.arguments as String), settings);
      default:
        return _fadeRoute(
          Scaffold(
            appBar: AppBar(),
            body: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return AppEmptyView(
                  title: l10n.routeNotFoundTitle,
                  message: l10n.routeNotFoundMessage(settings.name ?? ''),
                );
              },
            ),
          ),
          settings,
        );
    }
  }

  static Route<dynamic> _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: Motion.normal,
      reverseTransitionDuration: Motion.fast,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Motion.curve);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            // Horizontal, not vertical: forward navigation slides in from
            // the right, and Flutter's built-in reverse-on-pop then slides
            // the same page back out to the right on the way back - so
            // "back" finally reads as back, not as an identical motion in
            // reverse.
            position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(curved),
            child: ScaleTransition(
              scale: Tween(begin: 0.98, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
