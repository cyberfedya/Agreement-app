import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/sound/app_sound.dart';
import 'package:app/core/sound/sound_service.dart';
import 'package:app/features/agreement/domain/agreement_html.dart';
import 'package:app/features/agreement/domain/agreement_pdf.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/features/agreement/presentation/deal_completion_messages.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/shared/widgets/primary_button.dart';
class AgreementCompletedPage extends StatefulWidget {
  const AgreementCompletedPage({super.key, this.isFirstParty = true});

  /// Which side of the deal is viewing this screen - picks whether
  /// [Agreement.firstPartyRole] or [Agreement.secondPartyRole] drives the
  /// completion message. Defaults to the creator's side, the original
  /// (only) entry point before this screen was shared with the second party.
  final bool isFirstParty;

  @override
  State<AgreementCompletedPage> createState() => _AgreementCompletedPageState();
}
class _AgreementCompletedPageState extends State<AgreementCompletedPage> {
  late final ConfettiController _confetti = ConfettiController(duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    _confetti.play();
    HapticFeedback.mediumImpact();
    unawaited(context.read<SoundService>().play(AppSound.dealCreated));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }
  Future<void> _copy(BuildContext context, String html) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final plainText = html
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), ' ')
        .replaceAll(RegExp(r'</p>|<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
    await Clipboard.setData(ClipboardData(text: plainText));
    messenger.showSnackBar(SnackBar(content: Text(l10n.agreementCopied)));
  }
  Future<void> _exportPdf(BuildContext context, String html) => exportAgreementAsPdf(context, html);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Consumer<AgreementProvider>(
          builder: (context, provider, _) {
            final agreement = provider.agreement;
            if (agreement == null) {
              return AppEmptyView(
                title: l10n.agreementNotFoundTitle,
                message: l10n.agreementNotFoundMessage,
                action: FilledButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                  child: Text(l10n.commonHome),
                ),
              );
            }
            return CenteredContent(
              child: ListView(
                padding: const EdgeInsets.all(Insets.x20),
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ConfettiWidget(
                          confettiController: _confetti,
                          blastDirection: -pi / 2,
                          blastDirectionality: BlastDirectionality.explosive,
                          emissionFrequency: 0.35,
                          numberOfParticles: 12,
                          maxBlastForce: 18,
                          minBlastForce: 6,
                          gravity: 0.25,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.inversePrimary,
                          ],
                        ),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                        )
                            .animate()
                            .scale(
                              begin: const Offset(0.4, 0.4),
                              end: const Offset(1, 1),
                              duration: 500.ms,
                              curve: Curves.easeOutBack,
                            )
                            .fadeIn(duration: 250.ms),
                      ],
                    ),
                  ),
                  const SizedBox(height: Insets.x20),
                  Text(
                    dealCompletionMessage(
                      agreement.templateDomain,
                      widget.isFirstParty ? agreement.firstPartyRole : agreement.secondPartyRole,
                      l10n,
                    ),
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Insets.x8),
                  Text(
                    l10n.agreementSignedBy(
                      widget.isFirstParty ? (provider.secondPartyName ?? '') : (provider.firstPartyName ?? ''),
                    ),
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
          final l10n = AppLocalizations.of(context)!;
          return BottomActionBar(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context, agreement.html),
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: Text(l10n.commonCopy),
                  ),
                ),
                const SizedBox(width: Insets.x12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportPdf(context, agreement.html),
                    icon: const Icon(Icons.ios_share_outlined, size: 18),
                    label: Text(l10n.commonPdf),
                  ),
                ),
                const SizedBox(width: Insets.x12),
                Expanded(
                  child: PrimaryButton(
                    label: l10n.commonHome,
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