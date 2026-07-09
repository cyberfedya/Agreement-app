import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/services/tts_service.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/core/widgets/skeletons.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/questionnaire/presentation/widgets/agreement_preview_sheet.dart';
import 'package:app/features/questionnaire/presentation/widgets/question_card.dart';
import 'package:app/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// One question at a time, chosen live by the backend's Interview Planner
/// — there's no fixed list or total, so the flow just keeps going until the
/// planner says "ready_to_generate".
class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key, required this.dealId, required this.templateTitle});

  final String dealId;
  final String templateTitle;

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final TextEditingController _controller = TextEditingController();
  bool _showCheck = false;
  bool _hasText = false;
  int? _controllerBoundToFieldId;
  bool _closingSpoken = false;

  // Cached rather than looked up via context.read() in dispose(): by then
  // the element is deactivated and ancestor lookups are unsafe.
  QuestionnaireProvider? _provider;
  TtsService? _tts;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    final provider = context.read<QuestionnaireProvider>();
    Future.microtask(() => provider.start(widget.dealId));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tts = context.read<TtsService>();
    final provider = context.read<QuestionnaireProvider>();
    if (!identical(_provider, provider)) {
      _provider?.removeListener(_onProviderChanged);
      _provider = provider..addListener(_onProviderChanged);
    }
  }

  @override
  void dispose() {
    _tts?.stop();
    _provider?.removeListener(_onProviderChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  /// Keeps the text field in sync with whichever question is current —
  /// prefilled when going back to an already-answered one, empty for a
  /// fresh one from the planner — and reads each new question aloud.
  void _onProviderChanged() {
    if (_provider?.readyToGenerate ?? false) {
      final closing = _provider?.closingMessage;
      if (!_closingSpoken && closing != null) {
        _closingSpoken = true;
        _tts?.speak(closing);
      }
      return;
    }

    final field = _provider?.currentQuestion;
    if (field == null || field.fieldId == _controllerBoundToFieldId) return;
    _controllerBoundToFieldId = field.fieldId;
    final text = _provider!.answerFor(field.fieldId);
    _controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    _tts?.speak(field.fieldName);
  }

  Future<void> _submitAnswer(QuestionnaireProvider provider) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _showCheck = true);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() => _showCheck = false);
    await provider.submitAnswer(text);
  }

  void _showHelp(String question) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Зачем этот вопрос?'),
        content: Text('«$question» нужно, чтобы точно отразить это условие в договоре.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно'))],
      ),
    );
  }

  Future<void> _generate() async {
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
            if (provider.isLoading && provider.currentQuestion == null && !provider.readyToGenerate) {
              return const CenteredContent(
                child: Padding(
                  padding: EdgeInsets.all(Insets.x20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: 120, height: 14),
                      SizedBox(height: Insets.x32),
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
            if (provider.errorMessage != null && provider.currentQuestion == null && !provider.readyToGenerate) {
              return AppErrorView(
                message: provider.errorMessage!,
                onRetry: () => provider.start(widget.dealId),
              );
            }

            final field = provider.currentQuestion;

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
                              Text(
                                provider.readyToGenerate
                                    ? 'Готово к созданию'
                                    : 'Вопрос ${provider.position}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Insets.x8),
                        IconButton(
                          onPressed: () => AgreementPreviewSheet.show(
                            context,
                            questions: provider.allFields,
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
                        if (provider.readyToGenerate)
                          _ReadyToGenerateView(templateTitle: widget.templateTitle)
                        else if (field != null)
                          QuestionCard(
                            key: ValueKey(field.fieldId),
                            question: field,
                            controller: _controller,
                            onChanged: (_) {},
                            onSpeak: () => _tts?.speak(field.fieldName),
                          ),
                        IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _showCheck ? 1 : 0,
                            duration: Motion.fast,
                            child: Center(
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary),
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
          if (provider.currentQuestion == null && !provider.readyToGenerate) return const SizedBox.shrink();

          return BottomActionBar(
            child: Row(
              children: [
                IconButton(
                  onPressed: provider.canGoBack ? provider.goBack : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Предыдущий вопрос',
                ),
                if (!provider.readyToGenerate)
                  IconButton(
                    onPressed: provider.currentQuestion == null
                        ? null
                        : () => _showHelp(provider.currentQuestion!.fieldName),
                    icon: const Icon(Icons.help_outline_rounded),
                    tooltip: 'Помощь',
                  ),
                const SizedBox(width: Insets.x8),
                Expanded(
                  child: Consumer<AgreementProvider>(
                    builder: (context, agreementProvider, _) {
                      if (provider.readyToGenerate) {
                        return PrimaryButton(
                          label: 'Создать договор',
                          loading: agreementProvider.isLoading,
                          onPressed: _generate,
                        );
                      }
                      return PrimaryButton(
                        label: 'Далее',
                        icon: Icons.arrow_forward,
                        loading: provider.isLoading,
                        onPressed: _hasText ? () => _submitAnswer(provider) : null,
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

class _ReadyToGenerateView extends StatelessWidget {
  const _ReadyToGenerateView({required this.templateTitle});

  final String templateTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.x32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, color: theme.colorScheme.onPrimaryContainer, size: 36),
            ),
            const SizedBox(height: Insets.x20),
            Text('Достаточно информации', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: Insets.x8),
            Text(
              'Мы собрали всё необходимое для «$templateTitle». Можно создавать договор.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
