import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/deal/data/deal_repository.dart';
import 'package:app/features/deal/domain/deal.dart';
import 'package:app/shared/models/result.dart';

/// Full-screen "the AI is working" moment between Home and the question
/// flow. The free-form request is matched to a template by the backend
/// (an LLM call over the full template catalog — see
/// `CreateDealUseCase` on the server); a matched deal goes straight to the
/// interview, an unmatched one falls back to manual template selection.
class AiProcessingPage extends StatefulWidget {
  const AiProcessingPage({super.key, required this.requestText});

  final String requestText;

  @override
  State<AiProcessingPage> createState() => _AiProcessingPageState();
}

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
  late final Future<Result<Deal?>> _dealFuture;

  @override
  void initState() {
    super.initState();
    // Kick off the real classification request immediately; it runs
    // alongside the animation below rather than after it.
    _dealFuture = context.read<DealRepository>().createFromText(widget.requestText);
    _run();
  }

  Future<void> _run() async {
    // Wait for both: the animation gives a believable minimum duration,
    // the deal future is the actual (possibly slower) network+AI latency.
    final results = await Future.wait<dynamic>([_controller.forward(), _dealFuture]);
    if (!mounted) return;

    final navigator = Navigator.of(context);
    switch (results[1] as Result<Deal?>) {
      case Success(value: final deal?):
        navigator.pushReplacementNamed(
          AppRoutes.questionnaire,
          arguments: QuestionnaireRouteArgs(dealId: deal.id, templateTitle: deal.templateTitle),
        );
      case Success():
        // AI found no reasonable match — let the user pick manually.
        navigator.pushReplacementNamed(
          AppRoutes.templates,
          arguments: TemplatesRouteArgs(query: widget.requestText),
        );
      case Failure():
        // Network/server error — the picker's own error state can retry.
        navigator.pushReplacementNamed(
          AppRoutes.templates,
          arguments: TemplatesRouteArgs(query: widget.requestText),
        );
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
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: CenteredContent(
          child: Center(
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
          ),
        ),
      ),
    );
  }
}
