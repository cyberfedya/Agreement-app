import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/hold_to_talk_mic_button.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/features/templates/domain/template.dart';
import 'package:app/features/templates/providers/templates_list_provider.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/shared/animation/entrance.dart';
import 'package:app/shared/widgets/pressable_scale.dart';
import 'package:app/shared/widgets/primary_button.dart';
 
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  bool _hasText = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    // Best-effort: quick-start chips are a nice-to-have, never block the
    // core type-or-speak flow if the catalog fails to load.
    final templates = context.read<TemplatesListProvider>();
    Future.microtask(templates.load);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVoiceText(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Voice input previously failed completely silently on error - the
  /// button just stopped glowing with no explanation, indistinguishable
  /// from the user simply not having said anything worth keeping.
  void _showVoiceError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openQrScan() => Navigator.of(context).pushNamed(AppRoutes.qrScan);

  /// Blocks deal creation until the creator's own party details exist -
  /// otherwise the generated agreement would silently carry blank
  /// placeholders for "who" is selling/renting/hiring, discovered only
  /// much later at generation time instead of up front.
  Future<bool> _ensureProfileIsFilled() async {
    final profileRepository = context.read<ProfileRepository>();
    final profile = await profileRepository.getCurrent();
    if (profile != null && profile.fullName.trim().isNotEmpty) return true;
    if (!mounted) return false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.dealInviteFillProfileFirst)),
    );
    await Navigator.of(context).pushNamed(AppRoutes.profile);
    if (!mounted) return false;

    final updated = await profileRepository.getCurrent();
    return updated != null && updated.fullName.trim().isNotEmpty;
  }

  Future<void> _createAgreement() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    if (!await _ensureProfileIsFilled()) return;
    if (!mounted) return;
    Navigator.of(context).pushNamed(AppRoutes.aiProcessing, arguments: text);
  }

  void _openTemplate(TemplateSummary template) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pushNamed(AppRoutes.templateDetail, arguments: template.key);
  }

  static String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 5) return l10n.homeGreetingNight;
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 18) return l10n.homeGreetingDay;
    return l10n.homeGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: CenteredContent(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x8, Insets.x20, Insets.x20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _openQrScan,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      tooltip: l10n.homeScanQrTooltip,
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
                      icon: const Icon(Icons.person_outline_rounded),
                      tooltip: l10n.homeProfileTooltip,
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ).animateEntrance(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: Insets.x4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_greeting(l10n)}!',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: Insets.x4),
                                    Text(l10n.homeQuestion, style: theme.textTheme.headlineSmall),
                                    const SizedBox(height: Insets.x8),
                                    Text(
                                      l10n.homeSubtitle,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animateEntranceStaggered(1),
                              const SizedBox(height: Insets.x20),
                              _QuickStartChips(onSelected: _openTemplate).animateEntranceStaggered(2),
                              const SizedBox(height: Insets.x16),
                              AnimatedContainer(
                                duration: Motion.normal,
                                curve: Motion.curve,
                                width: double.infinity,
                                constraints: const BoxConstraints(minHeight: 180),
                                padding: const EdgeInsets.all(Insets.x20),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: Corners.xlRadius,
                                  border: Border.all(
                                    color: _listening ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                                    width: _listening ? 1.5 : 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  minLines: 4,
                                  maxLines: 8,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: theme.textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: l10n.homeHint,
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ).animateEntranceStaggered(3),
                              const SizedBox(height: Insets.x24),
                              HoldToTalkMicButton(
                                onTextChanged: _onVoiceText,
                                onListeningChanged: (value) => setState(() => _listening = value),
                                onPermissionDenied: () => _showVoiceError(l10n.voiceInputPermissionDenied),
                                onRecognitionError: () => _showVoiceError(l10n.voiceInputRecognitionError),
                                onNoSpeechDetected: () => _showVoiceError(l10n.voiceInputNoSpeechDetected),
                              ).animateEntranceStaggered(4),
                              const SizedBox(height: Insets.x12),
                              AnimatedSwitcher(
                                duration: Motion.fast,
                                child: Text(
                                  _listening ? l10n.homeListening : l10n.homeHoldToTalk,
                                  key: ValueKey(_listening),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _listening ? theme.colorScheme.primary : theme.colorScheme.outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                PrimaryButton(label: l10n.homeCreateAgreement, onPressed: _hasText ? _createAgreement : null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontal row of real templates from the catalog ([TemplatesListProvider])
/// - tapping one jumps straight to its detail page, the same entry point
/// the full template list uses. Silently absent while loading or on
/// failure: this is a shortcut, never a blocker for the core flow.
class _QuickStartChips extends StatelessWidget {
  const _QuickStartChips({required this.onSelected});

  final ValueChanged<TemplateSummary> onSelected;

  static const int _maxShown = 6;

  @override
  Widget build(BuildContext context) {
    return Consumer<TemplatesListProvider>(
      builder: (context, provider, _) {
        if (provider.templates.isEmpty) return const SizedBox.shrink();
        final shown = provider.templates.take(_maxShown).toList();

        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: shown.length,
            separatorBuilder: (_, _) => const SizedBox(width: Insets.x8),
            itemBuilder: (context, index) => _QuickStartChip(
              template: shown[index],
              onTap: () => onSelected(shown[index]),
            ),
          ),
        );
      },
    );
  }
}

class _QuickStartChip extends StatelessWidget {
  const _QuickStartChip({required this.template, required this.onTap});

  final TemplateSummary template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: Insets.x8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    template.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}