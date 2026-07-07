import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/shared/widgets/primary_button.dart';

class AgreementPage extends StatelessWidget {
  const AgreementPage({super.key});

  /// Rough HTML → plain-text conversion for the clipboard.
  static String _plainText(String html) => html
      .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), ' ')
      .replaceAll(RegExp(r'</p>|<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
      .trim();

  Future<void> _copy(BuildContext context, Agreement agreement) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _plainText(agreement.html)));
    messenger.showSnackBar(const SnackBar(content: Text('Agreement copied to clipboard')));
  }

  void _exportPdf(BuildContext context) {
    // PDF export ships in V2; this dialog is the sanctioned placeholder.
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF export'),
        content: const Text(
          'Saving and sharing as PDF is coming in the next release. '
          'For now you can copy the agreement text.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Consumer<AgreementProvider>(
        builder: (context, provider, _) {
          final agreement = provider.agreement;
          if (agreement == null) {
            return const AppEmptyView(
              title: 'Nothing to preview',
              message: 'Generate an agreement to see it here.',
            );
          }

          return CenteredContent(
            child: ListView(
              padding: const EdgeInsets.all(Insets.x20),
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: Insets.x8),
                    Expanded(
                      child: Text(
                        'Generated ${TimeOfDay.fromDateTime(agreement.generatedAt.toLocal()).format(context)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy text',
                      icon: const Icon(Icons.copy_outlined, size: 20),
                      onPressed: () => _copy(context, agreement),
                    ),
                    IconButton(
                      tooltip: 'Share / Export PDF',
                      icon: const Icon(Icons.ios_share_outlined, size: 20),
                      onPressed: () => _exportPdf(context),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.x12),

                // Paper-style document
                Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light
                        ? Colors.white
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: Corners.lgRadius,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  padding: const EdgeInsets.all(Insets.x20),
                  child: Html(data: agreement.html),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<AgreementProvider>(
        builder: (context, provider, _) {
          if (provider.agreement == null) return const SizedBox.shrink();
          return BottomActionBar(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context, provider.agreement!),
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: Insets.x12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Done',
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
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
