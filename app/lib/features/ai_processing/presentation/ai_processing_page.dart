import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/deal/data/deal_repository.dart';
import 'package:app/features/deal/domain/deal.dart';
import 'package:app/shared/models/result.dart';
class AiProcessingPage extends StatefulWidget {
  const AiProcessingPage({super.key, required this.requestText});

  final String requestText;

  @override
  State<AiProcessingPage> createState() => _AiProcessingPageState();
}

enum _Phase { processing, failed, noMatch }

class _AiProcessingPageState extends State<AiProcessingPage> with SingleTickerProviderStateMixin {
  static const _steps = [
    (0, 'Анализируем информацию…'),
    (28, 'Формируем структуру договора…'),
    (58, 'Определяем необходимые условия…'),
    (86, 'Почти готово…'),
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final Animation<double> _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

  _Phase _phase = _Phase.processing;
  String? _failureMessage;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _phase = _Phase.processing;
      _failureMessage = null;
    });
    _controller.forward(from: 0);

    // Kick off the real classification request; the animation gives a
    // believable minimum duration while the actual network+AI call runs.
    final dealFuture = context.read<DealRepository>().createFromText(widget.requestText);
    final results = await Future.wait<dynamic>([_controller.forward(), dealFuture]);
    if (!mounted) return;

    switch (results[1] as Result<Deal?>) {
      case Success(value: final deal?):
        // Document suggestions are now handled contextually mid-interview
        // (DocumentSuggestionEngine, backend-driven) instead of a blanket
        // pre-interview screen - go straight to the interview.
        final args = QuestionnaireRouteArgs(dealId: deal.id, templateTitle: deal.templateTitle);
        Navigator.of(context).pushReplacementNamed(AppRoutes.questionnaire, arguments: args);
      case Success():
        setState(() => _phase = _Phase.noMatch);
      case Failure(:final message):
        setState(() {
          _phase = _Phase.failed;
          _failureMessage = message;
        });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _messageFor(int percent) {
    var message = _steps.first.$2;
    for (final step in _steps) {
      if (percent >= step.$1) message = step.$2;
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CenteredContent(
          child: switch (_phase) {
            _Phase.processing => _buildProcessing(context),
            _Phase.failed => AppErrorView(
              message: _failureMessage ?? 'Не удалось связаться с сервером.',
              onRetry: _run,
            ),
            _Phase.noMatch => _NoMatchView(onEditRequest: () => Navigator.of(context).pop()),
          },
        ),
      ),
    );
  }

  Widget _buildProcessing(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          final percent = (_progress.value * 100).round();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 148,
                height: 148,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: _progress.value,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                      ),
                    ),
                    Text('$percent%', style: theme.textTheme.headlineMedium),
                  ],
                ),
              ),
              const SizedBox(height: Insets.x32),
              AnimatedSwitcher(
                duration: Motion.fast,
                child: Text(
                  _messageFor(percent),
                  key: ValueKey(_messageFor(percent)),
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoMatchView extends StatelessWidget {
  const _NoMatchView({required this.onEditRequest});

  final VoidCallback onEditRequest;

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
              padding: const EdgeInsets.all(Insets.x16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: Corners.lgRadius,
              ),
              child: Icon(Icons.search_off_rounded, size: 32, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: Insets.x16),
            Text('Не удалось определить тип договора', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: Insets.x8),
            Text(
              'Опишите подробнее, о чём хотите договориться — например, '
              '«продаю автомобиль» или «сдаю квартиру в аренду».',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: Insets.x24),
            FilledButton(onPressed: onEditRequest, child: const Text('Изменить запрос')),
          ],
        ),
      ),
    );
  }
}
