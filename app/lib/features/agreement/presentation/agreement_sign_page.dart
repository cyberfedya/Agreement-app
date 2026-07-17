import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import 'package:app/features/agreement/data/agreement_repository.dart';
import 'package:app/features/agreement/domain/agreement_html.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/features/agreement/presentation/widgets/negotiation_sheets.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/l10n/app_localizations.dart';
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

  /// Guards against navigating to the completion screen more than once -
  /// `refreshStatus` can notify several times while already fully signed.
  bool _navigatedToCompletion = false;

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
    if (provider.isFullySigned) {
      _goToCompletionIfFullySigned(provider);
      return;
    }
    _pollTimer ??= Timer.periodic(const Duration(seconds: 4), (_) async {
      final provider = context.read<AgreementProvider>();
      await provider.refreshStatus(widget.agreementKey);
      if (!mounted) return;
      if (provider.isFullySigned) {
        _pollTimer?.cancel();
        _goToCompletionIfFullySigned(provider);
      }
    });
  }

  /// Mirrors AgreementPage's own navigation to the completion screen, once
  /// both signatures are in - just for the second party's side, with
  /// `isFirstParty: false` so the completion message uses their role.
  void _goToCompletionIfFullySigned(AgreementProvider provider) {
    if (_navigatedToCompletion || !provider.isFullySigned) return;
    _navigatedToCompletion = true;
    // Same stack-collapsing navigation as AgreementPage's own call - see
    // its comment for why a plain pushReplacementNamed isn't enough.
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.agreementCompleted,
      ModalRoute.withName(AppRoutes.home),
      arguments: false,
    );
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
    final l10n = AppLocalizations.of(context)!;

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
        setState(() => _negotiationNotice = l10n.agreementSignProposalSent(proposal.label));
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
    final l10n = AppLocalizations.of(context)!;

    switch (await repository.requestClarification(widget.agreementKey, message: message, profileId: profileId)) {
      case Success():
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        setState(() => _negotiationNotice = l10n.agreementSignQuestionSent);
      case Failure(:final message):
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// The name recorded as the legal signatory. A real MyID integration
  /// would return the verified party's name from the identification step
  /// itself; without one, the second party's own profile - the same
  /// self-entered identity the first party's side already relies on - is
  /// the closest honest substitute. Blocks signing (rather than falling
  /// back to a placeholder name) until that profile is actually filled in.
  Future<String?> _resolveSignerName() async {
    final profileRepository = context.read<ProfileRepository>();
    var profile = await profileRepository.getCurrent();
    if (profile != null && profile.fullName.trim().isNotEmpty) return profile.fullName.trim();
    if (!mounted) return null;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.dealInviteFillProfileFirst)));
    await Navigator.of(context).pushNamed(AppRoutes.profile);
    if (!mounted) return null;

    profile = await profileRepository.getCurrent();
    return (profile != null && profile.fullName.trim().isNotEmpty) ? profile.fullName.trim() : null;
  }

  Future<void> _identifyAndSign() async {
    if (_verifying) return;
    final signerName = await _resolveSignerName();
    if (signerName == null || !mounted) return;

    setState(() => _verifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final success = await context.read<AgreementProvider>().signAsSecondParty(widget.agreementKey, signerName);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (!success) {
      final message = context.read<AgreementProvider>().errorMessage ?? l10n.agreementSignFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    _startPollingIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
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
              title: l10n.agreementDocumentUnavailableTitle,
              message: provider.errorMessage ?? l10n.agreementNotFoundOrNotGenerated,
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(l10n.agreementSignTitle)),
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
                    message: l10n.agreementFullySigned,
                  )
                else if (provider.isSecondPartySigned)
                  _StatusBanner(
                    icon: Icons.check_circle_outline,
                    message: l10n.agreementSecondPartySignedWaitingFirst,
                  )
                else if (provider.isFirstPartySigned)
                  _StatusBanner(
                    icon: Icons.info_outline,
                    message: l10n.agreementFirstPartySignedWaitingSecond,
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
                                l10n.agreementMyIdNotice,
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
                              label: Text(l10n.agreementProposeChange),
                            ),
                          ),
                          const SizedBox(width: Insets.x12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _verifying ? null : _askClarification,
                              icon: const Icon(Icons.help_outline_rounded, size: 20),
                              label: Text(l10n.agreementAskQuestion),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Insets.x12),
                      PrimaryButton(
                        label: l10n.agreementSignWithMyId,
                        loading: _verifying,
                        onPressed: _verifying ? null : _identifyAndSign,
                      ),
                      const SizedBox(height: Insets.x12),
                      // Same disclosure AuthPage shows next to its own MyID
                      // button - this is the other party's most legally
                      // significant moment in the whole flow, so it must be
                      // exactly as honest about the demo identification as
                      // the very first screen was, not silently omit it.
                      Text(
                        l10n.authDemoModeNotice,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
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
