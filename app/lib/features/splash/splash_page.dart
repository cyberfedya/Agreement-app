import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: Motion.slow)..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 600), () {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final curved = CurvedAnimation(parent: _controller, curve: Motion.curve);
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curved),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(Insets.x16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: Corners.lgRadius,
                  ),
                  child: Icon(Icons.handshake_outlined, size: 40, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: Insets.x16),
                Text(AppConfig.appName, style: theme.textTheme.headlineSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
