import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import 'package:app/features/agreement/domain/agreement_html.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// Second party's view after scanning the QR code: fetches the agreement
/// by deal id from the backend (so this works from any device, not just
/// the one that generated it), then a demo MyID identification step
/// before signing - which is also persisted via the backend.
class AgreementSignPage extends StatefulWidget {
  const AgreementSignPage({super.key, required this.agreementKey});

  /// The deal id encoded in the scanned QR code.
  final String agreementKey;

  @override
  State<AgreementSignPage> createState() => _AgreementSignPageState();
}

class _AgreementSignPageState extends State<AgreementSignPage> {
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AgreementProvider>();
    Future.microtask(() => provider.loadByDealId(widget.agreementKey));
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
    }
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
                if (provider.isFullySigned)
                  Container(
                    padding: const EdgeInsets.all(Insets.x16),
                    margin: const EdgeInsets.only(bottom: Insets.x16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: Corners.lgRadius,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 20, color: theme.colorScheme.onPrimaryContainer),
                        const SizedBox(width: Insets.x12),
                        Expanded(
                          child: Text(
                            'Подписано: ${provider.secondPartyName}',
                            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
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
          bottomNavigationBar: provider.isFullySigned
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
