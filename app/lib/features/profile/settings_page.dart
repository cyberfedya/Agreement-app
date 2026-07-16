import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/localization/locale_provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/services/tts_service.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/theme_mode_provider.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/l10n/app_localizations.dart';

/// Deliberately smaller than a typical "Настройки" screen: only items that
/// are actually wired to something real. No fake 2FA/device-list/PIN toggles
/// — those would just be decoration until there's a real account system
/// behind them.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _deleteProfile(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProfileDialogTitle),
        content: Text(l10n.deleteProfileDialogContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<ProfileRepository>().delete();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  static String _languageName(AppLocalizations l10n, Locale locale) {
    switch (locale.languageCode) {
      case 'uz':
        return l10n.languageUzbek;
      case 'en':
        return l10n.languageEnglish;
      default:
        return l10n.languageRussian;
    }
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();
    final chosen = await showModalBottomSheet<Locale>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Insets.x16),
              child: Text(l10n.settingsLanguagePickerTitle, style: Theme.of(sheetContext).textTheme.titleMedium),
            ),
            for (final locale in LocaleProvider.supportedLocales)
              ListTile(
                title: Text(_languageName(l10n, locale)),
                trailing: locale == localeProvider.locale ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.pop(sheetContext, locale),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) await localeProvider.setLocale(chosen);
  }

  static String _themeName(AppLocalizations l10n, ThemeMode mode) =>
      mode == ThemeMode.dark ? l10n.settingsThemeDark : l10n.settingsThemeLight;

  Future<void> _pickTheme(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final themeModeProvider = context.read<ThemeModeProvider>();
    final chosen = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Insets.x16),
              child: Text(l10n.settingsThemeTitle, style: Theme.of(sheetContext).textTheme.titleMedium),
            ),
            for (final mode in const [ThemeMode.light, ThemeMode.dark])
              ListTile(
                title: Text(_themeName(l10n, mode)),
                trailing: mode == themeModeProvider.mode ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.pop(sheetContext, mode),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) await themeModeProvider.setMode(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final themeModeProvider = context.watch<ThemeModeProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Insets.x20),
        children: [
          _SettingsCard(
            icon: Icons.translate_rounded,
            title: l10n.settingsLanguageTitle,
            subtitle: _languageName(l10n, localeProvider.locale),
            onTap: () => _pickLanguage(context),
          ),
          const SizedBox(height: Insets.x12),
          const _TtsToggleCard(),
          const SizedBox(height: Insets.x12),
          _SettingsCard(
            icon: Icons.palette_outlined,
            title: l10n.settingsThemeTitle,
            subtitle: _themeName(l10n, themeModeProvider.mode),
            onTap: () => _pickTheme(context),
          ),
          const SizedBox(height: Insets.x12),
          _SettingsCard(
            icon: Icons.info_outline_rounded,
            title: l10n.settingsAboutTitle,
            subtitle: l10n.settingsAboutSubtitle(AppConfig.appName),
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
              title: Text(l10n.settingsDeleteProfile, style: TextStyle(color: theme.colorScheme.error)),
              onTap: () => _deleteProfile(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showAboutDialog(
      context: context,
      applicationName: AppConfig.appName,
      applicationVersion: l10n.settingsAboutVersion,
    );
  }
}

/// On/off switch for the assistant's voice - persisted via [TtsService],
/// so muting survives restarts. The interview keeps working identically,
/// just silently.
class _TtsToggleCard extends StatefulWidget {
  const _TtsToggleCard();

  @override
  State<_TtsToggleCard> createState() => _TtsToggleCardState();
}

class _TtsToggleCardState extends State<_TtsToggleCard> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    final tts = context.read<TtsService>();
    Future.microtask(() async {
      final enabled = await tts.isEnabled();
      if (mounted) setState(() => _enabled = enabled);
    });
  }

  Future<void> _toggle(bool value) async {
    final tts = context.read<TtsService>();
    setState(() => _enabled = value);
    await tts.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: Corners.lgRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        secondary: Icon(Icons.record_voice_over_outlined, color: theme.colorScheme.primary),
        title: Text(l10n.settingsVoiceTitle),
        subtitle: Text(_enabled == false ? l10n.settingsVoiceSubtitleOff : l10n.settingsVoiceSubtitleOn),
        value: _enabled ?? true,
        onChanged: _enabled == null ? null : _toggle,
      ),
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
