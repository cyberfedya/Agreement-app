import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/features/profile/domain/user_profile.dart';

/// The identity EasyAgree substitutes into agreements as the creator's
/// party data. Values come from [ProfileRepository] — a demo identity
/// today, the real MyID-verified profile once that integration lands.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<UserProfile> _profile = context.read<ProfileRepository>().getCurrent();

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: FutureBuilder<UserProfile>(
        future: _profile,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          if (profile == null) {
            return const AppLoadingIndicator();
          }

          final fields = [
            ('Ф.И.О.', profile.fullName),
            ('Серия и номер паспорта', profile.passportNumber),
            ('Дата рождения', profile.birthDate),
            ('Адрес', profile.address),
          ];

          return CenteredContent(
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
                if (profile.verified)
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: Insets.x8),
                        Text(
                          'Подтверждено через MyID',
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
                      for (final (index, (label, value)) in fields.indexed) ...[
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
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Выйти'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
