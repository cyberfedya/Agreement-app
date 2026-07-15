import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/deal/domain/deal_history.dart';
import 'package:app/features/deal/presentation/widgets/deal_status_badge.dart';
import 'package:app/features/deal/providers/deal_history_provider.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/shared/models/result.dart';
import 'package:app/shared/widgets/primary_button.dart';

class DealHistoryDetailPage extends StatefulWidget {
  const DealHistoryDetailPage({super.key, required this.dealId});

  final String dealId;

  @override
  State<DealHistoryDetailPage> createState() => _DealHistoryDetailPageState();
}

class _DealHistoryDetailPageState extends State<DealHistoryDetailPage> {
  bool _isBusy = false;

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year}';
  }

  Future<void> _openDocument(DealSummary deal) async {
    setState(() => _isBusy = true);
    final agreementProvider = context.read<AgreementProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    await agreementProvider.loadByDealId(deal.id);
    if (!mounted) return;
    setState(() => _isBusy = false);

    if (agreementProvider.agreement == null) {
      messenger.showSnackBar(SnackBar(content: Text(agreementProvider.errorMessage ?? l10n.appErrorTitle)));
      return;
    }

    navigator.pushNamed(agreementProvider.isFullySigned ? AppRoutes.agreementCompleted : AppRoutes.agreement);
  }

  void _continueFillingIn(DealSummary deal) {
    Navigator.of(context).pushNamed(
      AppRoutes.questionnaire,
      arguments: QuestionnaireRouteArgs(dealId: deal.id, templateTitle: deal.templateTitle),
    );
  }

  Future<void> _cancelDeal(DealSummary deal) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.historyDetailCancelConfirmTitle),
        content: Text(l10n.historyDetailCancelConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.historyDetailCancelConfirmButton)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    final historyProvider = context.read<DealHistoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await historyProvider.cancel(deal.id);
    if (!mounted) return;
    setState(() => _isBusy = false);

    switch (result) {
      case Success():
        navigator.pop();
      case Failure(:final message):
        messenger.showSnackBar(SnackBar(content: Text(message.isEmpty ? l10n.historyDetailCancelFailed : message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Consumer<DealHistoryProvider>(
      builder: (context, provider, _) {
        final matches = provider.deals.where((d) => d.id == widget.dealId);
        final deal = matches.isEmpty ? null : matches.first;

        if (deal == null) {
          return Scaffold(
            appBar: AppBar(),
            body: AppErrorView(message: l10n.appErrorTitle),
          );
        }

        final isCancellable =
            deal.status == DealHistoryStatus.draft ||
            deal.status == DealHistoryStatus.waitingSecondParty ||
            deal.status == DealHistoryStatus.waitingYourSignature;

        return Scaffold(
          appBar: AppBar(title: Text(deal.templateTitle)),
          body: CenteredContent(
            child: ListView(
              padding: const EdgeInsets.all(Insets.x20),
              children: [
                _InfoRow(label: l10n.historyDetailStatusLabel, badge: DealStatusBadge(status: deal.status)),
                _InfoRow(label: l10n.historyDetailCreatedLabel, value: _formatDate(deal.createdAt)),
                _InfoRow(label: l10n.historyDetailUpdatedLabel, value: _formatDate(deal.updatedAt)),
                if (deal.secondPartyName != null && deal.secondPartyName!.isNotEmpty)
                  _InfoRow(label: l10n.historyDetailSecondPartyLabel, value: deal.secondPartyName!),
                if (deal.status == DealHistoryStatus.cancelled) ...[
                  const SizedBox(height: Insets.x12),
                  Container(
                    padding: const EdgeInsets.all(Insets.x16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: Corners.mdRadius,
                    ),
                    child: Text(
                      l10n.historyDetailCancelledNotice,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(Insets.x20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (deal.status == DealHistoryStatus.draft)
                  PrimaryButton(
                    label: l10n.historyDetailContinue,
                    loading: _isBusy,
                    onPressed: _isBusy ? null : () => _continueFillingIn(deal),
                  )
                else if (deal.status != DealHistoryStatus.cancelled)
                  PrimaryButton(
                    label: l10n.historyDetailOpenDocument,
                    loading: _isBusy,
                    onPressed: _isBusy ? null : () => _openDocument(deal),
                  ),
                if (isCancellable) ...[
                  const SizedBox(height: Insets.x8),
                  OutlinedButton(
                    onPressed: _isBusy ? null : () => _cancelDeal(deal),
                    child: Text(l10n.historyDetailCancelDeal),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.badge});

  final String label;
  final String? value;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.x16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          badge ?? Text(value ?? '', style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
