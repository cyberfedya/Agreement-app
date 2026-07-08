import 'package:flutter/material.dart';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';

/// Demo identification screen. There is no real MyID integration yet — this
/// screen exists to show users *how* sign-in will work once MyID is wired
/// up, and to unblock the rest of the flow behind a believable gate.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _verifying = false;

  Future<void> _continueWithMyId() async {
    setState(() => _verifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: CenteredContent(
          child: Padding(
            padding: const EdgeInsets.all(Insets.x24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: Corners.lgRadius,
                  ),
                  child: Icon(Icons.verified_user_outlined, size: 34, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: Insets.x20),
                Text(AppConfig.appName, style: theme.textTheme.headlineMedium),
                const SizedBox(height: Insets.x8),
                Text(
                  'Договоры с юридической силой',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const Spacer(flex: 2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Insets.x20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: Corners.lgRadius,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: Insets.x8),
                          Text('Идентификация через MyID', style: theme.textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: Insets.x8),
                      Text(
                        'Ваше имя, фамилия и паспортные данные будут подтверждены '
                        'через MyID и автоматически подставлены в договор.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.x20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _verifying ? null : _continueWithMyId,
                    child: _verifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : const Text('Продолжить с MyID'),
                  ),
                ),
                const SizedBox(height: Insets.x12),
                Text(
                  _verifying ? 'Проверяем данные…' : 'Демо-режим — реальная интеграция появится позже',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
