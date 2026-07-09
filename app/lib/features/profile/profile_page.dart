import 'package:flutter/material.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _demoFields = [
    ('Ф.И.О.', 'Иванов Иван Иванович'),
    ('Серия и номер паспорта', 'AD 1234567'),
    ('Дата рождения', '01.01.1990'),
    ('Адрес', 'г. Ташкент, ул. Примерная, 1'),
  ];

  void _logout(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: CenteredContent(
        child: ListView(
          padding: const EdgeInsets.all(Insets.x20),
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.person_rounded, size: 40, color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: Insets.x16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: Insets.x8),
                  Text(
                    'Подтверждено через MyID (демо)',
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.x24),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: Corners.lgRadius,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  for (final (index, (label, value)) in _demoFields.indexed) ...[
                    if (index > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(Insets.x16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                          Text(value, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Insets.x16),
            Text(
              'Эти данные автоматически подставляются в договор как данные вашей '
              'стороны — в интервью они не запрашиваются.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: Insets.x32),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }
}
