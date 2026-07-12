import 'package:flutter/material.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/hold_to_talk_mic_button.dart';
import 'package:app/shared/animation/entrance.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// "О чём договариваемся?" — the entire product starts here. One input,
/// one microphone, one action. Everything else is a distraction.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
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
    Navigator.of(context).pushNamed(AppRoutes.aiProcessing, arguments: text);
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
                      tooltip: 'Scan QR',
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
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 220),
                          padding: const EdgeInsets.all(Insets.x20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: Corners.xlRadius,
                            border: Border.all(color: theme.colorScheme.outlineVariant),
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
                        ).animateEntranceStaggered(1),
                        const SizedBox(height: Insets.x32),
                        HoldToTalkMicButton(onTextChanged: _onVoiceText).animateEntranceStaggered(2),
                      ],
                    ),
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
