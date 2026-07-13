import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import 'package:app/features/agreement/data/agreement_repository.dart';
import 'package:app/features/agreement/domain/agreement_html.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/features/agreement/presentation/widgets/negotiation_sheets.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/shared/models/result.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// Second party's view after scanning the QR code: fetches the agreement
/// by deal id from the backend (so this works from any device, not just
/// the one that generated it), then a demo MyID identification step
/// before signing - which is also persisted via the backend. Polls for the
/// first party's signature the same way [AgreementPage] polls for this
/// party's, since either side may sign first.
class AgreementSignPage extends StatefulWidget {
  const AgreementSignPage({super.key, required this.agreementKey});

  /// The deal id encoded in the scanned QR code.
  final String agreementKey;

  @override
  State<AgreementSignPage> createState() => _AgreementSignPageState();
}

class _AgreementSignPageState extends State<AgreementSignPage> {
  bool _verifying = false;
  Timer? _pollTimer;

  /// Set after a proposal or clarification was successfully recorded -
  /// shows a "передано первой стороне" banner instead of pretending
  /// nothing happened. Signing stays available: the parties may agree
  /// verbally and sign as-is.
  String? _negotiationNotice;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AgreementProvider>();
    Future.microtask(() async {
      await provider.loadByDealId(widget.agreementKey);
      if (mounted) _startPollingIfNeeded();
    });
  }

  void _startPollingIfNeeded() {
    final provider = context.read<AgreementProvider>();
    if (provider.isFullySigned) return;
    _pollTimer ??= Timer.periodic(const Duration(seconds: 4), (_) async {
      final provider = context.read<AgreementProvider>();
      await provider.refreshStatus(widget.agreementKey);
      if (provider.isFullySigned) _pollTimer?.cancel();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _proposeChange() async {
    final proposal = await ProposeChangeSheet.show(context, dealId: widget.agreementKey);
    if (proposal == null || !mounted) return;

    final repository = context.read<AgreementRepository>();
    final profileId = await context.read<ProfileRepository>().getProfileId();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    switch (await repository.proposeFieldChange(
      widget.agreementKey,
      fieldId: proposal.fieldId,
      proposedValue: proposal.proposedValue,
      reason: proposal.reason,
      profileId: profileId,
    )) {
      case Success():
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        setState(() => _negotiationNotice = 'Предложение по «${proposal.label}» передано второй стороне.');
      case Failure(:final message):
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _askClarification() async {
    final message = await ClarificationSheet.show(context);
    if (message == null || !mounted) return;

    final repository = context.read<AgreementRepository>();
    final profileId = await context.read<ProfileRepository>().getProfileId();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    switch (await repository.requestClarification(widget.agreementKey, message: message, profileId: profileId)) {
      case Success():
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        setState(() => _negotiationNotice = 'Вопрос передан второй стороне.');
      case Failure(:final message):
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _identifyAndSign() async {
    if (_verifying) return;
    setState(() => _verifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    // Demo MyID: a real integration would return the verified party's
    // legal name here instead of this placeholder.
    final success = await context.read<AgreementProvider>().signAsSecondParty(
      widget.agreementKey,
      'Иванов Иван Иванович',
    );
    if (!mounted) return;
    setState(() => _verifying = false);
    if (!success) {
      final message = context.read<AgreementProvider>().errorMessage ?? 'Не удалось подписать договор.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    _startPollingIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AgreementProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(body: AppLoadingIndicator());
        }

        final agreement = provider.agreement;
        if (agreement == null || agreement.key != widget.agreementKey) {
          return Scaffold(
            appBar: AppBar(),
            body: AppEmptyView(
              title: 'Документ недоступен',
              message: provider.errorMessage ?? 'Этот договор не найден или ещё не сформирован.',
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Договор на подпись')),
          body: CenteredContent(
            child: ListView(
              padding: const EdgeInsets.all(Insets.x20),
              children: [
                if (_negotiationNotice != null)
                  Container(
                    padding: const EdgeInsets.all(Insets.x16),
                    margin: const EdgeInsets.only(bottom: Insets.x16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: Corners.lgRadius,
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.forward_to_inbox_outlined, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: Insets.x12),
                        Expanded(child: Text(_negotiationNotice!, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                if (provider.isFullySigned)
                  _StatusBanner(
                    icon: Icons.check_circle_outline,
                    message: 'Договор полностью подписан.',
                  )
                else if (provider.isSecondPartySigned)
                  _StatusBanner(
                    icon: Icons.check_circle_outline,
                    message: 'Вы подписали договор.\nОжидание первой стороны.',
                  )
                else if (provider.isFirstPartySigned)
                  _StatusBanner(
                    icon: Icons.info_outline,
                    message: 'Первая сторона уже подписала договор.\nПодпишите, чтобы завершить договор.',
                  ),
                if (provider.isFullySigned || provider.isSecondPartySigned || provider.isFirstPartySigned)
                  const SizedBox(height: Insets.x4),
                Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: Corners.lgRadius,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  padding: const EdgeInsets.all(Insets.x20),
                  child: Html(data: sanitizeAgreementHtml(agreement.html)),
                ),
              ],
            ),
          ),
          bottomNavigationBar: provider.isSecondPartySigned
              ? null
              : BottomActionBar(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(Insets.x16),
                        margin: const EdgeInsets.only(bottom: Insets.x12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: Corners.lgRadius,
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.badge_outlined, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: Insets.x12),
                            Expanded(
                              child: Text(
                                'Перед подписью — идентификация через MyID. '
                                'Ваши имя и данные подставятся в договор автоматически.',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _verifying ? null : _proposeChange,
                              icon: const Icon(Icons.edit_note_rounded, size: 20),
                              label: const Text('Изменить условие'),
                            ),
                          ),
                          const SizedBox(width: Insets.x12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _verifying ? null : _askClarification,
                              icon: const Icon(Icons.help_outline_rounded, size: 20),
                              label: const Text('Задать вопрос'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Insets.x12),
                      PrimaryButton(
                        label: 'Пройти MyID и подписать',
                        loading: _verifying,
                        onPressed: _verifying ? null : _identifyAndSign,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Insets.x16),
      margin: const EdgeInsets.only(bottom: Insets.x16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: Corners.lgRadius,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: Insets.x12),
          Expanded(
            child: Text(message, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
          ),
        ],
      ),
    );
  }
}
