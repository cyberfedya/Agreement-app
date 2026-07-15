import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/network/api_exception.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/features/profile/domain/user_profile.dart';
import 'package:app/l10n/app_localizations.dart';

/// Self-entered identity — no mock data, no fake MyID verification badge.
/// Whatever the user types here is what's substituted into agreements as
/// the creator's party details, and is saved to the backend keyed by this
/// device's profile id (see [ProfileRepository]).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _fullName = TextEditingController();
  final _passportNumber = TextEditingController();
  final _birthDate = TextEditingController();
  final _address = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repository = context.read<ProfileRepository>();
    UserProfile? profile;
    String? loadError;
    try {
      profile = await repository.getCurrent();
    } on ApiException catch (e) {
      // A saved profile not loading must never trap the user on an
      // infinite spinner - fall through to an empty, editable form (they
      // can still fill it in and save) instead of hanging on a network
      // blip that a bare `NotFoundException` catch didn't cover.
      loadError = e.message;
    }
    if (!mounted) return;

    if (profile != null) {
      _fullName.text = profile.fullName;
      _passportNumber.text = profile.passportNumber;
      _birthDate.text = profile.birthDate;
      _address.text = profile.address;
    }
    setState(() => _isLoading = false);

    if (loadError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.profileLoadFailed(loadError))));
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await context.read<ProfileRepository>().save(
        UserProfile(
          fullName: _fullName.text.trim(),
          passportNumber: _passportNumber.text.trim(),
          birthDate: _birthDate.text.trim(),
          address: _address.text.trim(),
        ),
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaveFailed)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _passportNumber.dispose();
    _birthDate.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.profileSettingsTooltip,
          ),
        ],
      ),
      body: _isLoading
          ? const AppLoadingIndicator()
          : CenteredContent(
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
                  const SizedBox(height: Insets.x24),
                  Text(
                    l10n.profileIntro,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                  ),
                  const SizedBox(height: Insets.x24),
                  Material(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: Corners.mdRadius,
                    child: InkWell(
                      borderRadius: Corners.mdRadius,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.dealHistory),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x12),
                        child: Row(
                          children: [
                            Icon(Icons.history_rounded, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: Insets.x12),
                            Expanded(child: Text(l10n.profileHistoryEntry, style: theme.textTheme.titleSmall)),
                            Icon(Icons.chevron_right_rounded, size: 20, color: theme.colorScheme.outline),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Insets.x24),
                  _Field(label: l10n.profileFullNameLabel, controller: _fullName, hint: l10n.profileFullNameHint),
                  const SizedBox(height: Insets.x16),
                  _Field(label: l10n.profilePassportLabel, controller: _passportNumber, hint: l10n.profilePassportHint),
                  const SizedBox(height: Insets.x16),
                  _Field(label: l10n.profileBirthDateLabel, controller: _birthDate, hint: l10n.profileBirthDateHint),
                  const SizedBox(height: Insets.x16),
                  _Field(label: l10n.profileAddressLabel, controller: _address, hint: l10n.profileAddressHint),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(Insets.x20),
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(l10n.commonSave),
              ),
            ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller, required this.hint});

  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: Insets.x8),
        TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
      ],
    );
  }
}
