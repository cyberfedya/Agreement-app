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
import 'package:app/features/profile/data/profile_repository.dart';
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
  bool _signing = false;

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
    messenger.showSnackBar(const SnackBar(content: Text('Договор скопирован')));
  }

  Future<void> _exportPdf(BuildContext context, String html) => exportAgreementAsPdf(context, html);

  /// Signs as the first party (creator) using the name saved on this
  /// device's profile - the same identity already rendered into the
  /// agreement's first-party fields.
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
    final fullName = profile?.fullName.trim();
    final success = await provider.signAsFirstParty(dealId, (fullName == null || fullName.isEmpty) ? 'Первая сторона' : fullName);
    if (!mounted) return;
    setState(() => _signing = false);
    if (!success) {
      final message = provider.errorMessage ?? 'Не удалось подписать договор.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

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
              title: 'Договор ещё не создан',
              message: 'Пройдите интервью и создайте договор — он появится здесь.',
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
                    message: 'Вы подписали договор.\nОжидание второй стороны.',
                  ),
                if (!provider.isFirstPartySigned && provider.isSecondPartySigned)
                  _SignStatusBanner(
                    icon: Icons.info_outline,
                    message: 'Вторая сторона уже подписала договор.\nПодпишите, чтобы завершить договор.',
                  ),
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
                      tooltip: 'Скопировать текст',
                      icon: const Icon(Icons.copy_outlined, size: 20),
                      onPressed: () => _copy(context, agreement),
                    ),
                    IconButton(
                      tooltip: 'Поделиться / PDF',
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
                PrimaryButton(
                  label: provider.isFirstPartySigned ? 'Вы подписали договор' : 'Подписать договор',
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
                        label: const Text('Копировать'),
                      ),
                    ),
                    const SizedBox(width: Insets.x12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                        child: const Text('На главную'),
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

/// Where the deal is right now, as three calm steps: created ✓, waiting
/// for both signatures (active, gently pulsing while this page polls the
/// backend), completed. The page auto-advances to the completed screen the
/// moment the backend reports BOTH signatures, so the third step never
/// shows as done here - it's the promise of what's next.
class _DealStepsIndicator extends StatelessWidget {
  const _DealStepsIndicator({required this.firstPartySigned, required this.secondPartySigned});

  final bool firstPartySigned;
  final bool secondPartySigned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final signedCount = (firstPartySigned ? 1 : 0) + (secondPartySigned ? 1 : 0);
    final middleLabel = switch (signedCount) {
      0 => 'Ожидание подписи обеих сторон',
      1 => 'Ожидание подписи второй стороны',
      _ => 'Обе стороны подписали',
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
          const Expanded(child: _DealStep(label: 'Создан', state: _StepState.done)),
          _StepConnector(color: theme.colorScheme.primary),
          Expanded(
            flex: 2,
            child: _DealStep(label: middleLabel, state: signedCount == 2 ? _StepState.done : _StepState.active),
          ),
          _StepConnector(color: signedCount == 2 ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
          Expanded(
            child: _DealStep(label: 'Завершено', state: signedCount == 2 ? _StepState.active : _StepState.pending),
          ),
        ],
      ),
    );
  }
}

/// Highlights whichever half of the two-sided signature is already done -
/// distinct from a generic status message, since which text shows depends
/// on which party this device belongs to.
class _SignStatusBanner extends StatelessWidget {
  const _SignStatusBanner({required this.icon, required this.message});

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
  // Created eagerly in initState: a `late final` initializer would run on
  // first *access*, and for non-active steps that first access is
  // dispose() itself - where creating a ticker (ancestor lookup on a
  // deactivated element) crashes the framework.
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
