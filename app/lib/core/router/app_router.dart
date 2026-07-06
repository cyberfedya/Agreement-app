import 'package:flutter/widgets.dart';

abstract class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String qr = '/qr';
  static const String questionnaire = '/questionnaire';
  static const String agreement = '/agreement';
  static const String profile = '/profile';
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    throw UnimplementedError('Route not implemented: ${settings.name}');
  }
}
