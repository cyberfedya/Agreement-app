import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/core/widgets/progress_header.dart';
import 'package:app/core/widgets/skeletons.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/questionnaire/presentation/widgets/question_card.dart';
import 'package:app/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// One-question-at-a-time flow with a progress header. Answers auto-save
/// into the provider on every keystroke, so moving back and forth never
/// loses input.
class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key, required this.templateKey});

  final String templateKey;

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final PageController _pageController = PageController();
  final Map<int, TextEditingController> _controllers = {};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<QuestionnaireProvider>();
    Future.microtask(() => provider.load(widget.templateKey));
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

  Future<void> _submit() async {
    final questionnaire = context.read<QuestionnaireProvider>();
    final agreementProvider = context.read<AgreementProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await agreementProvider.generate(widget.templateKey, questionnaire.answers);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Questionnaire')),
      body: Consumer<QuestionnaireProvider>(
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
              onRetry: () => provider.load(widget.templateKey),
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
                  child: ProgressHeader(current: _currentIndex + 1, total: questions.length),
                ),
                Expanded(
                  child: PageView.builder(
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
                        autofocus: index == _currentIndex,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
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
                if (_currentIndex > 0)
                  OutlinedButton(
                    onPressed: () => _goTo(_currentIndex - 1),
                    child: const Text('Back'),
                  ),
                if (_currentIndex > 0) const SizedBox(width: Insets.x12),
                Expanded(
                  child: Consumer<AgreementProvider>(
                    builder: (context, agreementProvider, _) {
                      if (isLast) {
                        return PrimaryButton(
                          label: 'Generate',
                          loading: agreementProvider.isLoading,
                          onPressed: provider.canSubmit ? _submit : null,
                        );
                      }
                      return PrimaryButton(
                        label: 'Next',
                        icon: Icons.arrow_forward,
                        onPressed: currentAnswered ? () => _goTo(_currentIndex + 1) : null,
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
