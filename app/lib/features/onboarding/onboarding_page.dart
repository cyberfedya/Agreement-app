import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/storage/local_storage.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// Three-beat first-launch intro: describe the deal -> upload a document
/// -> sign via QR. Shown once ([seenKey] in [LocalStorage]); the splash
/// screen routes around it on every later launch.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const String seenKey = 'onboarding_seen';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _page = 0;

  static const _slides = [
    (
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Просто расскажите,\nо чём договариваетесь',
      body: 'Своими словами или голосом — ИИ сам поймёт, какой договор нужен, и подготовит его.',
    ),
    (
      icon: Icons.document_scanner_outlined,
      title: 'Сфотографируйте документ —\nостальное заполнится само',
      body: 'Техпаспорт, кадастровые документы, реквизиты: ИИ распознает их и заполнит договор автоматически.',
    ),
    (
      icon: Icons.qr_code_2_rounded,
      title: 'Вторая сторона подписывает\nпо QR-коду',
      body: 'Покажите код — партнёр откроет договор у себя, предложит правки или сразу подпишет.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final storage = context.read<LocalStorage>();
    final navigator = Navigator.of(context);
    await storage.write(OnboardingPage.seenKey, 'true');
    navigator.pushReplacementNamed(AppRoutes.login);
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _finish();
    } else {
      _pageController.nextPage(duration: Motion.slow, curve: Motion.curve);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: CenteredContent(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, Insets.x8, Insets.x12, 0),
                  child: TextButton(onPressed: _finish, child: const Text('Пропустить')),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Insets.x32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                            ),
                            child: Center(
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.primaryContainer,
                                ),
                                child: Icon(slide.icon, size: 38, color: theme.colorScheme.onPrimaryContainer),
                              ),
                            ),
                          ),
                          const SizedBox(height: Insets.x40),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(height: 1.25),
                          ),
                          const SizedBox(height: Insets.x16),
                          Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Insets.x24, 0, Insets.x24, Insets.x24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _slides.length; i++)
                          AnimatedContainer(
                            duration: Motion.fast,
                            curve: Motion.curve,
                            width: i == _page ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: Insets.x4),
                            decoration: BoxDecoration(
                              color: i == _page ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Insets.x20),
                    PrimaryButton(label: isLast ? 'Начать' : 'Далее', onPressed: _next),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
