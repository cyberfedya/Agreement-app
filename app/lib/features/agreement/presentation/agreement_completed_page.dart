import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/features/agreement/domain/agreement_html.dart';
import 'package:app/features/agreement/domain/agreement_pdf.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/shared/widgets/primary_button.dart';
class AgreementCompletedPage extends StatelessWidget {
  const AgreementCompletedPage({super.key});

  Future<void> _copy(BuildContext context, String html) async {
    final messenger = ScaffoldMessenger.of(context);
    final plainText = html
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), ' ')
        .replaceAll(RegExp(r'</p>|<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
    await Clipboard.setData(ClipboardData(text: plainText));
    messenger.showSnackBar(const SnackBar(content: Text('Договор скопирован')));
  }

  Future<void> _exportPdf(BuildContext context, String html) => exportAgreementAsPdf(context, html);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Consumer<AgreementProvider>(
          builder: (context, provider, _) {
            final agreement = provider.agreement;
            if (agreement == null) {
              return AppEmptyView(
                title: 'Договор не найден',
                message: 'Похоже, вы попали сюда напрямую. Начните новую сделку с главного экрана.',
                action: FilledButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                  child: const Text('На главную'),
                ),
              );
            }
            return CenteredContent(
              child: ListView(
                padding: const EdgeInsets.all(Insets.x20),
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: Insets.x20),
                  Text('Договор успешно подписан', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: Insets.x8),
                  Text(
                    'Подписал(а): ${provider.secondPartyName}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: Insets.x24),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? Colors.white
                          : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: Corners.lgRadius,
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    padding: const EdgeInsets.all(Insets.x20),
                    child: Html(data: sanitizeAgreementHtml(agreement.html)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Consumer<AgreementProvider>(
        builder: (context, provider, _) {
          final agreement = provider.agreement;
          if (agreement == null) return const SizedBox.shrink();
          return BottomActionBar(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context, agreement.html),
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('Копировать'),
                  ),
                ),
                const SizedBox(width: Insets.x12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportPdf(context, agreement.html),
                    icon: const Icon(Icons.ios_share_outlined, size: 18),
                    label: const Text('PDF'),
                  ),
                ),
                const SizedBox(width: Insets.x12),
                Expanded(
                  child: PrimaryButton(
                    label: 'На главную',
                    onPressed: () =>
                        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}