import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/agreement/data/agreement_repository.dart';
import 'package:app/features/agreement/domain/deal_invite.dart';
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

  void _accept() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.agreementSign, arguments: widget.dealId);
  }

  void _decline() {
    setState(() => _declined = true);
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
                      child: OutlinedButton(onPressed: _decline, child: const Text('Отклонить')),
                    ),
                    const SizedBox(width: Insets.x12),
                    Expanded(
                      child: PrimaryButton(label: 'Принять', onPressed: _accept),
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
    _ => status,
  };
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
