import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/agreement/data/agreement_repository.dart';
import 'package:app/features/agreement/domain/deal_invite.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/shared/models/result.dart';
import 'package:app/shared/widgets/primary_button.dart';

class DealInvitePage extends StatefulWidget {
  const DealInvitePage({super.key, required this.dealId});

  final String dealId;

  @override
  State<DealInvitePage> createState() => _DealInvitePageState();
}

class _DealInvitePageState extends State<DealInvitePage> {
  bool _isLoading = true;
  String? _errorMessage;
  DealInvite? _invite;
  bool _declined = false;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final repository = context.read<AgreementRepository>();
    switch (await repository.getInvite(widget.dealId)) {
      case Success(:final value):
        setState(() {
          _invite = value;
          _isLoading = false;
        });
      case Failure(:final message):
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
    }
  }

  Future<void> _accept() async {
    setState(() => _isAccepting = true);

    final agreementRepository = context.read<AgreementRepository>();
    final profileRepository = context.read<ProfileRepository>();
    final agreementProvider = context.read<AgreementProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final profileId = await profileRepository.getProfileId();
    switch (await agreementRepository.acceptInvite(widget.dealId, profileId)) {
      case Success():
        // The agreement was generated before this device was linked, so
        // its fields were still blank placeholders - regenerate now that
        // this profile is attached, so the document picks it up before
        // it's shown.
        await agreementProvider.generate(widget.dealId, const {});
        if (!mounted) return;
        navigator.pushReplacementNamed(AppRoutes.agreementSign, arguments: widget.dealId);
      case Failure(:final message):
        if (!mounted) return;
        setState(() => _isAccepting = false);
        messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Declining is a real backend action now (the first party sees it),
  /// so ask for an optional reason first and only show the declined view
  /// once the server has recorded it.
  Future<void> _decline() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.xl)),
      ),
      builder: (sheetContext) => const _DeclineReasonSheet(),
    );
    if (reason == null || !mounted) return;

    final repository = context.read<AgreementRepository>();
    final profileRepository = context.read<ProfileRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isAccepting = true);

    final profileId = await profileRepository.getProfileId();
    switch (await repository.declineInvite(widget.dealId, reason: reason.isEmpty ? null : reason, profileId: profileId)) {
      case Success():
        if (!mounted) return;
        setState(() {
          _isAccepting = false;
          _declined = true;
        });
      case Failure(:final message):
        if (!mounted) return;
        setState(() => _isAccepting = false);
        messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Приглашение к сделке')),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_errorMessage != null) {
              return AppErrorView(message: _errorMessage!, onRetry: () {
                setState(() => _isLoading = true);
                _load();
              });
            }
            if (_declined) {
              return _DeclinedView(
                onBackHome: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
              );
            }

            final invite = _invite!;
            return CenteredContent(
              child: Padding(
                padding: const EdgeInsets.all(Insets.x20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Вас пригласили принять участие в сделке',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: Insets.x24),
                    _InfoRow(label: 'Тип сделки', value: invite.transactionType),
                    _InfoRow(label: 'Ваша роль', value: roleLabel(invite.expectedSecondPartyRole)),
                    _InfoRow(label: 'Пригласил', value: invite.invitedBy ?? 'Не указано'),
                    _InfoRow(label: 'Статус', value: _statusLabel(invite.inviteStatus)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: (_isLoading || _errorMessage != null || _declined)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x12, Insets.x20, Insets.x20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isAccepting ? null : _decline,
                        child: const Text('Отклонить'),
                      ),
                    ),
                    const SizedBox(width: Insets.x12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Принять',
                        loading: _isAccepting,
                        onPressed: _isAccepting ? null : _accept,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  static String _statusLabel(String status) => switch (status) {
    'Pending' => 'Ожидает подтверждения',
    'Opened' => 'Открыто',
    'Accepted' => 'Принято',
    'Declined' => 'Отклонено',
    'ChangeRequested' => 'Предложены изменения',
    'ClarificationRequested' => 'Запрошено уточнение',
    _ => status,
  };
}

/// Optional-reason prompt before declining: pops with `''` for "decline
/// without a reason", a non-empty string for a reason, or null if the
/// user backs out entirely.
class _DeclineReasonSheet extends StatefulWidget {
  const _DeclineReasonSheet();

  @override
  State<_DeclineReasonSheet> createState() => _DeclineReasonSheetState();
}

class _DeclineReasonSheetState extends State<_DeclineReasonSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Insets.x24,
          Insets.x24,
          Insets.x24,
          Insets.x24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Отклонить приглашение?', style: theme.textTheme.titleLarge),
            const SizedBox(height: Insets.x8),
            Text(
              'Вторая сторона увидит ваш ответ. Можете коротко объяснить почему — это необязательно.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: Insets.x16),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Причина (необязательно)…'),
            ),
            const SizedBox(height: Insets.x16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Назад'),
                  ),
                ),
                const SizedBox(width: Insets.x12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _controller.text.trim()),
                    child: const Text('Отклонить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: Insets.x4),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _DeclinedView extends StatelessWidget {
  const _DeclinedView({required this.onBackHome});

  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.x32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: Insets.x16),
            Text('Вы отклонили приглашение', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: Insets.x20),
            PrimaryButton(label: 'На главную', onPressed: onBackHome),
          ],
        ),
      ),
    );
  }
}
