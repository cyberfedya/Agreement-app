import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/agreement/presentation/agreement_page.dart';
import 'package:app/features/home/presentation/home_page.dart';
import 'package:app/features/questionnaire/presentation/pages/questionnaire_page.dart';
import 'package:app/features/splash/splash_page.dart';
import 'package:app/features/templates/presentation/template_detail_page.dart';
import 'package:app/features/templates/presentation/templates_list_page.dart';

abstract class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';

  /// Optional `String` argument: pre-selected category.
  static const String templates = '/templates';

  /// Required `String` argument: template key.
  static const String templateDetail = '/templates/detail';

  /// Required `String` argument: template key.
  static const String questionnaire = '/questionnaire';

  static const String agreement = '/agreement';
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _fadeRoute(const SplashPage(), settings);
      case AppRoutes.home:
        return _fadeRoute(const HomePage(), settings);
      case AppRoutes.templates:
        return _fadeRoute(TemplatesListPage(initialCategory: settings.arguments as String?), settings);
      case AppRoutes.templateDetail:
        return _fadeRoute(TemplateDetailPage(templateKey: settings.arguments as String), settings);
      case AppRoutes.questionnaire:
        return _fadeRoute(QuestionnairePage(templateKey: settings.arguments as String), settings);
      case AppRoutes.agreement:
        return _fadeRoute(const AgreementPage(), settings);
      default:
        return _fadeRoute(
          Scaffold(
            appBar: AppBar(),
            body: AppEmptyView(
              title: 'Page not found',
              message: 'The screen "${settings.name}" does not exist in this build.',
            ),
          ),
          settings,
        );
    }
  }

  /// Subtle fade + upward slide shared by every route (200–300ms).
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
            position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
