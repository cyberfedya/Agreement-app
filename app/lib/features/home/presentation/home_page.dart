import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/hold_to_talk_mic_button.dart';
import 'package:app/features/templates/domain/template.dart';
import 'package:app/features/templates/providers/templates_list_provider.dart';
import 'package:app/shared/animation/entrance.dart';
import 'package:app/shared/widgets/pressable_scale.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// "О чём договариваемся?" — the entire product starts here. One input,
/// one microphone, one action; quick-start chips are the only optional
/// shortcut, built from the real template catalog rather than a fixed list.
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

  void _openQrScan() => Navigator.of(context).pushNamed(AppRoutes.qrScan);

  void _createAgreement() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).pushNamed(AppRoutes.aiProcessing, arguments: text);
  }

  void _openTemplate(TemplateSummary template) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pushNamed(AppRoutes.templateDetail, arguments: template.key);
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Доброй ночи';
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      tooltip: 'Сканировать QR',
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
                      icon: const Icon(Icons.person_outline_rounded),
                      tooltip: 'Профиль',
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
                                      '${_greeting()}!',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: Insets.x4),
                                    Text('О чём договариваемся?', style: theme.textTheme.headlineSmall),
                                    const SizedBox(height: Insets.x8),
                                    Text(
                                      'Опишите словами или голосом — я подготовлю договор автоматически.',
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
                                  decoration: const InputDecoration(
                                    hintText: 'Скажите или напишите, о чём хотите договориться…',
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
                              ).animateEntranceStaggered(4),
                              const SizedBox(height: Insets.x12),
                              AnimatedSwitcher(
                                duration: Motion.fast,
                                child: Text(
                                  _listening ? 'Слушаю…' : 'Удерживайте, чтобы говорить',
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
                PrimaryButton(label: 'Создать договор', onPressed: _hasText ? _createAgreement : null),
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
