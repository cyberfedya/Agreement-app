import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/services/tts_service.dart';
import 'package:app/core/sound/app_sound.dart';
import 'package:app/core/sound/sound_service.dart';
import 'package:app/core/sound/sound_settings_provider.dart';
import 'package:app/features/agreement/domain/agreement_html.dart';
import 'package:app/features/agreement/domain/agreement_pdf.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/features/agreement/domain/agreement.dart';
import 'package:app/features/agreement/domain/agreement_qr.dart';
import 'package:app/features/agreement/domain/deal_invite.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/shared/animation/entrance.dart';
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
  AgreementProvider? _provider;
  Timer? _pollTimer;
  bool _signing = false;

  /// One-shot guard so the "second party joined" TTS/sound announcement
  /// fires exactly once, the first time `acceptedAt` transitions from null
  /// to non-null - not on every poll while it stays non-null.
  bool _wasAccepted = false;

  /// Same one-shot pattern as [_wasAccepted], for the second party's
  /// signature - [AppSound.partyJoined] already covers "joined or signed"
  /// (see its doc comment) but was only ever wired up for the join case.
  bool _wasSecondPartySigned = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<AgreementProvider>();
    if (!identical(_provider, provider)) {
      _provider?.removeListener(_onProviderChanged);
      _wasAccepted = provider.agreement?.acceptedAt != null;
      _wasSecondPartySigned = provider.isSecondPartySigned;
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

    final accepted = _provider!.agreement?.acceptedAt != null;
    if (accepted && !_wasAccepted) {
      _wasAccepted = true;
      unawaited(_announceSecondPartyJoined());
    }

    final secondPartySigned = _provider!.isSecondPartySigned;
    if (secondPartySigned && !_wasSecondPartySigned) {
      _wasSecondPartySigned = true;
      unawaited(context.read<SoundService>().play(AppSound.partyJoined));
    }

    if (_provider!.isFullySigned) {
      _pollTimer?.cancel();
      // Collapses the whole stack down to Home (not just this page) - a
      // plain pushReplacementNamed left QuestionnairePage sitting directly
      // beneath this route, so the system back gesture on the completed
      // screen resurfaced the finished interview instead of exiting to
      // Home.
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.agreementCompleted,
        ModalRoute.withName(AppRoutes.home),
        arguments: true,
      );
    }
  }

  Future<void> _announceSecondPartyJoined() async {
    final soundSettings = context.read<SoundSettingsProvider>();
    unawaited(context.read<SoundService>().play(AppSound.partyJoined));
    if (soundSettings.level == SoundLevel.off) return;

    final l10n = AppLocalizations.of(context)!;
    final role = roleLabel(_provider?.agreement?.secondPartyRole, l10n);
    await context.read<TtsService>().speak(l10n.agreementSecondPartyJoinedAnnouncement(role));
  }
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
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: _plainText(agreement.html)));
    messenger.showSnackBar(SnackBar(content: Text(l10n.agreementCopied)));
  }

  Future<void> _exportPdf(BuildContext context, String html) => exportAgreementAsPdf(context, html);
  Future<void> _signAsFirstParty() async {
    if (_signing) return;
    setState(() => _signing = true);
    final provider = context.read<AgreementProvider>();
    final dealId = provider.agreement?.key;
    final profile = await context.read<ProfileRepository>().getCurrent();
    if (!mounted || dealId == null) {
      if (mounted) setState(() => _signing = false);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final fullName = profile?.fullName.trim();
    final success = await provider.signAsFirstParty(
      dealId,
      (fullName == null || fullName.isEmpty) ? l10n.agreementFirstPartyFallback : fullName,
    );
    if (!mounted) return;
    setState(() => _signing = false);
    if (!success) {
      final message = provider.errorMessage ?? l10n.agreementSignFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.agreementTitle)),
      body: Consumer<AgreementProvider>(
        builder: (context, provider, _) {
          final agreement = provider.agreement;
          if (agreement == null) {
            return AppEmptyView(
              title: l10n.agreementNotCreatedTitle,
              message: l10n.agreementNotCreatedMessage,
            );
          }

          return CenteredContent(
            child: ListView(
              padding: const EdgeInsets.all(Insets.x20),
              children: [
                _DealStepsIndicator(
                  firstPartySigned: provider.isFirstPartySigned,
                  secondPartySigned: provider.isSecondPartySigned,
                ),
                const SizedBox(height: Insets.x24),

                if (provider.isFirstPartySigned && !provider.isSecondPartySigned)
                  _SignStatusBanner(
                    icon: Icons.check_circle_outline,
                    message: l10n.agreementYouSignedWaitingSecond,
                  ),
                if (!provider.isFirstPartySigned && provider.isSecondPartySigned)
                  _SignStatusBanner(
                    key: const ValueKey('second-signed-banner'),
                    icon: Icons.info_outline,
                    message: l10n.agreementSecondSignedWaitingYou,
                  ).animateEntrance(),
                if (provider.isFirstPartySigned || provider.isSecondPartySigned)
                  const SizedBox(height: Insets.x16),

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
                  l10n.agreementQrInstructions,
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
                        l10n.agreementCreatedAt(TimeOfDay.fromDateTime(agreement.generatedAt.toLocal()).format(context)),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.agreementCopyTextTooltip,
                      icon: const Icon(Icons.copy_outlined, size: 20),
                      onPressed: () => _copy(context, agreement),
                    ),
                    IconButton(
                      tooltip: l10n.agreementSharePdfTooltip,
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
          final l10n = AppLocalizations.of(context)!;
          return BottomActionBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: provider.isFirstPartySigned ? l10n.agreementYouSigned : l10n.agreementSignButton,
                  loading: _signing,
                  onPressed: (provider.isFirstPartySigned || _signing) ? null : _signAsFirstParty,
                ),
                const SizedBox(height: Insets.x8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copy(context, agreement),
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: Text(l10n.commonCopy),
                      ),
                    ),
                    const SizedBox(width: Insets.x12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                        child: Text(l10n.commonHome),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
class _DealStepsIndicator extends StatelessWidget {
  const _DealStepsIndicator({required this.firstPartySigned, required this.secondPartySigned});

  final bool firstPartySigned;
  final bool secondPartySigned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final signedCount = (firstPartySigned ? 1 : 0) + (secondPartySigned ? 1 : 0);
    final middleLabel = switch (signedCount) {
      0 => l10n.agreementWaitingBothSignatures,
      1 => l10n.agreementWaitingSecondSignature,
      _ => l10n.agreementBothSigned,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: Corners.lgRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(child: _DealStep(label: l10n.agreementStepCreated, state: _StepState.done)),
          _StepConnector(color: theme.colorScheme.primary),
          Expanded(
            flex: 2,
            child: _DealStep(label: middleLabel, state: signedCount == 2 ? _StepState.done : _StepState.active),
          ),
          _StepConnector(color: signedCount == 2 ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
          Expanded(
            child: _DealStep(label: l10n.agreementStepCompleted, state: signedCount == 2 ? _StepState.active : _StepState.pending),
          ),
        ],
      ),
    );
  }
}
class _SignStatusBanner extends StatelessWidget {
  const _SignStatusBanner({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Insets.x16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: Corners.lgRadius,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: Insets.x12),
          Expanded(
            child: Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
          ),
        ],
      ),
    );
  }
}

enum _StepState { done, active, pending }

class _DealStep extends StatefulWidget {
  const _DealStep({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  State<_DealStep> createState() => _DealStepState();
}

class _DealStepState extends State<_DealStep> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.55,
      upperBound: 1,
    );
    if (widget.state == _StepState.active) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (widget.state) {
      _StepState.done || _StepState.active => theme.colorScheme.primary,
      _StepState.pending => theme.colorScheme.outline,
    };

    return Column(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: switch (widget.state) {
            _StepState.done => Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: Icon(Icons.check_rounded, size: 14, color: theme.colorScheme.onPrimary),
            ),
            _StepState.active => FadeTransition(
              opacity: _pulse,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                ),
              ),
            ),
            _StepState.pending => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
              ),
            ),
          },
        ),
        const SizedBox(height: Insets.x8),
        Text(
          widget.label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: widget.state == _StepState.pending ? theme.colorScheme.outline : theme.colorScheme.onSurface,
            fontWeight: widget.state == _StepState.active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: Insets.x24),
      color: color,
    );
  }
}