import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/profile/data/profile_repository.dart';

/// Deliberately smaller than a typical "Настройки" screen: only items that
/// are actually wired to something real. No fake 2FA/device-list/PIN toggles
/// — those would just be decoration until there's a real account system
/// behind them.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _deleteProfile(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить профиль?'),
        content: const Text('Ваши сохранённые данные (Ф.И.О., паспорт, адрес) будут удалены с сервера.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<ProfileRepository>().delete();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(Insets.x20),
        children: [
          _SettingsCard(
            icon: Icons.translate_rounded,
            title: 'Язык интервью',
            subtitle: 'Русский',
            onTap: () => _showLanguageInfo(context),
          ),
          const SizedBox(height: Insets.x12),
          const _SettingsCard(icon: Icons.palette_outlined, title: 'Тема', subtitle: 'Светлая'),
          const SizedBox(height: Insets.x12),
          _SettingsCard(
            icon: Icons.info_outline_rounded,
            title: 'О программе',
            subtitle: '${AppConfig.appName} · демо-версия',
            onTap: () => _showAbout(context),
          ),
          const SizedBox(height: Insets.x24),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: Corners.lgRadius,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
              title: Text('Удалить профиль', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () => _deleteProfile(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Язык интервью'),
        content: const Text(
          'Сейчас вопросы задаются на русском. Выбор языка появится, '
          'когда интерфейс приложения станет многоязычным.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно'))],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConfig.appName,
      applicationVersion: 'Демо-версия',
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.icon, required this.title, required this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: Corners.lgRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
