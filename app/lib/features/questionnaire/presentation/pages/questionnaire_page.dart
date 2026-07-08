import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/core/widgets/progress_header.dart';
import 'package:app/core/widgets/skeletons.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/questionnaire/presentation/widgets/agreement_preview_sheet.dart';
import 'package:app/features/questionnaire/presentation/widgets/question_card.dart';
import 'package:app/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// One-question-at-a-time flow with a progress header. Answers auto-save
/// into the provider on every keystroke, so moving back and forth never
/// loses input.
class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key, required this.dealId, required this.templateTitle});

  final String dealId;
  final String templateTitle;

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final PageController _pageController = PageController();
  final Map<int, TextEditingController> _controllers = {};
  int _currentIndex = 0;
  bool _showCheck = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<QuestionnaireProvider>();
    Future.microtask(() => provider.load(widget.dealId));
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int fieldId, QuestionnaireProvider provider) =>
      _controllers.putIfAbsent(fieldId, () => TextEditingController(text: provider.answerFor(fieldId)));

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(index, duration: Motion.normal, curve: Motion.curve);
  }

  /// A brief checkmark flash before advancing — the document feels like
  /// it's being assembled brick by brick, not just paginated.
  Future<void> _confirmAndAdvance(int nextIndex) async {
    setState(() => _showCheck = true);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    setState(() => _showCheck = false);
    _goTo(nextIndex);
  }

  void _showHelp(String fieldName) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Зачем этот вопрос?'),
        content: Text('Поле «$fieldName» нужно, чтобы точно отразить это условие в договоре.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно'))],
      ),
    );
  }

  Future<void> _submit() async {
    final questionnaire = context.read<QuestionnaireProvider>();
    final agreementProvider = context.read<AgreementProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await agreementProvider.generate(widget.dealId, questionnaire.answers);
    if (!mounted) return;

    if (success) {
      navigator.pushNamed(AppRoutes.agreement);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(agreementProvider.errorMessage ?? 'Could not generate the agreement.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Consumer<QuestionnaireProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const CenteredContent(
                child: Padding(
                  padding: EdgeInsets.all(Insets.x20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: 80, height: 14),
                      SizedBox(height: Insets.x8),
                      Skeleton(height: 6, radius: 4),
                      SizedBox(height: Insets.x32),
                      Skeleton(width: 120, height: 14),
                      SizedBox(height: Insets.x12),
                      Skeleton(height: 24),
                      SizedBox(height: Insets.x8),
                      Skeleton(width: 240, height: 24),
                      SizedBox(height: Insets.x24),
                      Skeleton(height: 56, radius: Corners.sm),
                    ],
                  ),
                ),
              );
            }
            if (provider.errorMessage != null) {
              return AppErrorView(
                message: provider.errorMessage!,
                onRetry: () => provider.load(widget.dealId),
              );
            }
            if (provider.questions.isEmpty) {
              return const AppEmptyView(
                title: 'No questions',
                message: 'This template has no questionnaire.',
              );
            }

            final questions = provider.questions;
            return CenteredContent(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x12, Insets.x20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.templateTitle, style: theme.textTheme.titleMedium),
                              const SizedBox(height: Insets.x8),
                              ProgressHeader(current: _currentIndex + 1, total: questions.length),
                            ],
                          ),
                        ),
                        const SizedBox(width: Insets.x8),
                        IconButton(
                          onPressed: () => AgreementPreviewSheet.show(
                            context,
                            questions: questions,
                            answers: provider.answers,
                          ),
                          icon: const Icon(Icons.description_outlined),
                          tooltip: 'Предпросмотр договора',
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceContainerHigh,
                            foregroundColor: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: questions.length,
                          onPageChanged: (index) => setState(() => _currentIndex = index),
                          itemBuilder: (context, index) {
                            final question = questions[index];
                            return QuestionCard(
                              question: question,
                              controller: _controllerFor(question.fieldId, provider),
                              onChanged: (value) => provider.setAnswer(question.fieldId, value),
                              autofocus: false,
                            );
                          },
                        ),
                        IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _showCheck ? 1 : 0,
                            duration: Motion.fast,
                            child: Center(
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.primary,
                                ),
                                child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Consumer<QuestionnaireProvider>(
        builder: (context, provider, _) {
          final questions = provider.questions;
          if (provider.isLoading || questions.isEmpty) return const SizedBox.shrink();

          final isLast = _currentIndex == questions.length - 1;
          final question = questions[_currentIndex];
          final currentAnswered = !question.required || provider.isAnswered(question.fieldId);

          return BottomActionBar(
            child: Row(
              children: [
                IconButton(
                  onPressed: _currentIndex > 0 ? () => _goTo(_currentIndex - 1) : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Предыдущий вопрос',
                ),
                IconButton(
                  onPressed: () => _showHelp(question.fieldName),
                  icon: const Icon(Icons.help_outline_rounded),
                  tooltip: 'Помощь',
                ),
                const SizedBox(width: Insets.x8),
                Expanded(
                  child: Consumer<AgreementProvider>(
                    builder: (context, agreementProvider, _) {
                      if (isLast) {
                        return PrimaryButton(
                          label: 'Создать договор',
                          loading: agreementProvider.isLoading,
                          onPressed: provider.canSubmit ? _submit : null,
                        );
                      }
                      return PrimaryButton(
                        label: 'Далее',
                        icon: Icons.arrow_forward,
                        onPressed: currentAnswered ? () => _confirmAndAdvance(_currentIndex + 1) : null,
                      );
                    },
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
