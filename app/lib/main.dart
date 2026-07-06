import 'package:flutter/material.dart';
import 'package:app/core/config/app_config.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/splash/splash_page.dart';

void main() {
  runApp(const EasyAgreeApp());
}

class EasyAgreeApp extends StatelessWidget {
  const EasyAgreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const SplashPage(),
    );
  }
}
