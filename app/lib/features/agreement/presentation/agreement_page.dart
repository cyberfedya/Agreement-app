import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/features/agreement/domain/agreement_html.dart';
import 'package:app/features/agreement/domain/agreement_pdf.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/features/agreement/domain/agreement_qr.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// Shown right after generation: the document plus a QR code the second
/// party scans to view and sign it. Auto-advances to
/// [AppRoutes.agreementCompleted] the moment [AgreementProvider] reports a
/// signature (see that page's docs for why signing is same-session-only).
class AgreementPage extends StatefulWidget {
  const AgreementPage({super.key});

  @override
  State<AgreementPage> createState() => _AgreementPageState();
}

class _AgreementPageState extends State<AgreementPage> {
  // Cached rather than looked up via context.read() in dispose(): by then
  // the element is deactivated and ancestor lookups are unsafe.
  AgreementProvider? _provider;
  Timer? _pollTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<AgreementProvider>();
    if (!identical(_provider, provider)) {
      _provider?.removeListener(_onProviderChanged);
      _provider = provider..addListener(_onProviderChanged);
      _startPollingIfNeeded();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _provider?.removeListener(_onProviderChanged);
    super.dispose();
  }

  /// The second party signs on their own device after scanning the QR
  /// code - there's no push mechanism, so this device has to periodically
  /// ask the backend whether that's happened yet.
  void _startPollingIfNeeded() {
    final agreement = _provider?.agreement;
    if (agreement == null || _provider!.isFullySigned) return;
    _pollTimer ??= Timer.periodic(const Duration(seconds: 4), (_) {
      final dealId = _provider?.agreement?.key;
      if (dealId != null) _provider?.refreshStatus(dealId);
    });
  }

  void _onProviderChanged() {
    _startPollingIfNeeded();
    if (_provider!.isFullySigned) {
      _pollTimer?.cancel();
      Navigator.of(context).pushReplacementNamed(AppRoutes.agreementCompleted);
    }
  }

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

  Future<void> _exportPdf(BuildContext context, String html) => exportAgreementAsPdf(context, html);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Договор')),
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
                Container(
                  padding: const EdgeInsets.all(Insets.x16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: Corners.lgRadius,
                  ),
                  child: Row( 
                    children: [
                      Icon(Icons.hourglass_top_rounded, size: 20, color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: Insets.x12),
                      Expanded(
                        child: Text(
                          'Ожидает подпись второй стороны',
                          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.x24),

                Center(
                  child: Container(
                    padding: const EdgeInsets.all(Insets.x16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: Corners.lgRadius),
                    child: QrImageView(
                      data: buildAgreementQrPayload(agreement.key),
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: Insets.x12),
                Text(
                  'Покажите этот QR-код второй стороне — она отсканирует его, '
                  'пройдёт идентификацию через MyID и подпишет договор.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: Insets.x24),

                Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: Insets.x8),
                    Expanded(
                      child: Text(
                        'Создан ${TimeOfDay.fromDateTime(agreement.generatedAt.toLocal()).format(context)}',
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
                      onPressed: () => _exportPdf(context, agreement.html),
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
                  child: Html(data: sanitizeAgreementHtml(agreement.html)),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<AgreementProvider>(
        builder: (context, provider, _) {
          final agreement = provider.agreement;
          if (agreement == null) return const SizedBox.shrink();
          return BottomActionBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copy(context, agreement),
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: Insets.x12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'На главную',
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.x8),
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRoutes.agreementSign, arguments: agreement.key),
                  child: const Text('Открыть как вторая сторона (на этом устройстве)'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
