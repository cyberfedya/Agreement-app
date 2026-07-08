import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// Second party's view after scanning the QR code: read-only document,
/// then a demo MyID identification step before signing.
///
/// There is no backend endpoint yet to fetch a generated agreement by key
/// from a different session, so this reads the same in-memory
/// [AgreementProvider] the first party generated it into — real
/// cross-device retrieval is future work, not this screen's concern.
class AgreementSignPage extends StatefulWidget {
  const AgreementSignPage({super.key, required this.agreementKey});

  final String agreementKey;

  @override
  State<AgreementSignPage> createState() => _AgreementSignPageState();
}

class _AgreementSignPageState extends State<AgreementSignPage> {
  bool _verifying = false;

  Future<void> _identifyAndSign() async {
    setState(() => _verifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    // Demo MyID: a real integration would return the verified party's
    // legal name here instead of this placeholder.
    context.read<AgreementProvider>().signAsSecondParty('Иванов Иван Иванович');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final agreement = context.watch<AgreementProvider>().agreement;

    if (agreement == null || agreement.key != widget.agreementKey) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppEmptyView(
          title: 'Документ недоступен',
          message: 'Этот договор не найден в текущей демо-сессии.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Договор на подпись')),
      body: CenteredContent(
        child: ListView(
          padding: const EdgeInsets.all(Insets.x20),
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surfaceContainerHigh,
                borderRadius: Corners.lgRadius,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              padding: const EdgeInsets.all(Insets.x20),
              child: Html(data: agreement.html),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
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
              onPressed: _identifyAndSign,
            ),
          ],
        ),
      ),
    );
  }
}
