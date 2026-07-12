import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/services/tts_service.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/core/widgets/skeletons.dart';
import 'package:app/features/agreement/providers/agreement_provider.dart';
import 'package:app/features/documents/providers/document_upload_provider.dart';
import 'package:app/features/questionnaire/domain/interview_step.dart';
import 'package:app/features/questionnaire/domain/question.dart';
import 'package:app/features/questionnaire/presentation/widgets/agreement_preview_sheet.dart';
import 'package:app/features/questionnaire/presentation/widgets/question_card.dart';
import 'package:app/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:app/shared/widgets/primary_button.dart';


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
  String? _lastSpokenQuestionText;

  /// True while a document picked via the attach icon is being uploaded
  /// and OCR-processed - this can take several seconds, so the attach
  /// icon disables and an overlay makes the wait visible instead of the
  /// screen looking stuck.
  bool _attaching = false;

  QuestionnaireProvider? _provider;
  TtsService? _tts;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    final provider = context.read<QuestionnaireProvider>();
    final documentUploadProvider = context.read<DocumentUploadProvider>();
    Future.microtask(() {
      documentUploadProvider.attachDeal(widget.dealId);
      return provider.start(widget.dealId);
    });
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
    if (field == null) return;

    final sameField = field.fieldId == _controllerBoundToFieldId;
    final textChanged = field.fieldName != _lastSpokenQuestionText;
    if (sameField && !textChanged) return;

    _controllerBoundToFieldId = field.fieldId;
    _lastSpokenQuestionText = field.fieldName;

    // A repeated question (side remark handled, interview didn't move on)
    // keeps the same fieldId but comes back with new text woven in -
    // clear the box instead of reusing the goBack()-style answer prefill,
    // so the user isn't left staring at the remark they just sent.
    final text = sameField ? '' : _provider!.answerFor(field.fieldId);
    _controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    _tts?.speak(field.fieldName);
  }

  Future<void> _submitAnswer(QuestionnaireProvider provider, {String? textOverride}) async {
    final text = (textOverride ?? _controller.text).trim();
    if (text.isEmpty) return;
    setState(() => _showCheck = true);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() => _showCheck = false);
    await provider.submitAnswer(text);
  }

  /// Fired when speech recognition settles on a final transcript - answers
  /// the question immediately, the same as tapping "Далее", so a spoken
  /// answer never waits on a separate confirmation tap.
  void _onVoiceSubmit(String text) {
    final provider = context.read<QuestionnaireProvider>();
    if (provider.isLoading) return;
    unawaited(_submitAnswer(provider, textOverride: text));
  }

  /// Lets the user attach a photo/scan for the current question instead of
  /// typing it - available on every question, not just when
  /// [QuestionnaireProvider.documentSuggestion] proactively suggests one.
  Future<void> _attachDocument() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Камера'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Галерея'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final files = source == ImageSource.camera
        ? await picker.pickImage(source: ImageSource.camera, imageQuality: 85).then((f) => f == null ? <XFile>[] : [f])
        : await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty || !mounted) return;

    final entries = <(String, String, List<int>)>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      entries.add((file.name, file.mimeType ?? 'image/jpeg', bytes));
    }
    if (!mounted) return;

    setState(() => _attaching = true);
    final uploadProvider = context.read<DocumentUploadProvider>();
    final questionnaireProvider = context.read<QuestionnaireProvider>();
    try {
      final success = await uploadProvider.upload(entries);
      if (!mounted) return;

      if (success) {
        await questionnaireProvider.resumeAfterDocumentUpload();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(uploadProvider.errorMessage ?? 'Не удалось загрузить документ.')));
      }
    } finally {
      if (mounted) setState(() => _attaching = false);
    }
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
            if (provider.isLoading &&
                provider.currentQuestion == null &&
                !provider.readyToGenerate &&
                provider.documentSuggestion == null) {
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
            if (provider.errorMessage != null &&
                provider.currentQuestion == null &&
                !provider.readyToGenerate &&
                provider.documentSuggestion == null) {
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
                                provider.documentSuggestion != null
                                    ? 'Загрузка документа'
                                    : provider.readyToGenerate
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
                        if (provider.documentSuggestion != null)
                          _DocumentSuggestionView(suggestion: provider.documentSuggestion!)
                        else if (provider.readyToGenerate)
                          _ReviewConfirmView(templateTitle: widget.templateTitle)
                        else if (field != null)
                          QuestionCard(
                            key: ValueKey(field.fieldId),
                            question: field,
                            controller: _controller,
                            onChanged: (_) {},
                            onSpeak: () => _tts?.speak(field.fieldName),
                            onVoiceSubmit: _onVoiceSubmit,
                            onAttach: _attaching ? null : _attachDocument,
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
                        if (_attaching)
                          IgnorePointer(
                            child: Container(
                              color: theme.colorScheme.surface.withValues(alpha: 0.85),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: Insets.x16),
                                    Text(
                                      'Обрабатываю документ…',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
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

/// Shown once the interview has everything it needs, before the "Создать
/// договор" button does anything irreversible - every collected answer is
/// listed and editable in place, so a misheard or misread value can be
/// fixed without restarting the interview from scratch.
class _ReviewConfirmView extends StatelessWidget {
  const _ReviewConfirmView({required this.templateTitle});

  final String templateTitle;

  Future<void> _editField(BuildContext context, QuestionnaireProvider provider, Question field) async {
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => _EditFieldDialog(label: field.fieldName, initialValue: provider.answerFor(field.fieldId)),
    );
    if (newValue == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.editAnswer(field.fieldId, field.fieldName, newValue);
    if (!ok && context.mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Не удалось сохранить изменение')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<QuestionnaireProvider>(
      builder: (context, provider, _) {
        final collected = provider.allFields.where((f) => provider.answers.containsKey(f.fieldId)).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x8, Insets.x20, Insets.x32),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, color: theme.colorScheme.onPrimaryContainer, size: 24),
                ),
                const SizedBox(width: Insets.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Проверьте данные', style: theme.textTheme.titleLarge),
                      Text(
                        'Прежде чем создать «$templateTitle», убедитесь, что всё верно',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.x24),
            for (final field in collected)
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.x8),
                child: Material(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: Corners.lgRadius,
                  child: InkWell(
                    borderRadius: Corners.lgRadius,
                    onTap: () => _editField(context, provider, field),
                    child: Padding(
                      padding: const EdgeInsets.all(Insets.x16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field.fieldName,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: Insets.x4),
                                Text(provider.answerFor(field.fieldId), style: theme.textTheme.bodyLarge),
                              ],
                            ),
                          ),
                          const SizedBox(width: Insets.x8),
                          Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Non-mandatory "upload this instead of typing N fields" screen - shown
/// in place of the next question, never mixed into the same screen as one.
/// Uploading resumes the interview (skipping whatever got filled);
/// "Продолжить без документа" dismisses it for good and resumes normally.
class _DocumentSuggestionView extends StatefulWidget {
  const _DocumentSuggestionView({required this.suggestion});

  final DocumentSuggestion suggestion;

  @override
  State<_DocumentSuggestionView> createState() => _DocumentSuggestionViewState();
}

class _DocumentSuggestionViewState extends State<_DocumentSuggestionView> {
  final _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _pickFromCamera() async {
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo == null || !mounted) return;
    await _upload([photo]);
  }

  Future<void> _pickFromGallery() async {
    final photos = await _picker.pickMultiImage(imageQuality: 85);
    if (photos.isEmpty || !mounted) return;
    await _upload(photos);
  }

  Future<void> _upload(List<XFile> files) async {
    final entries = <(String, String, List<int>)>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      entries.add((file.name, file.mimeType ?? 'image/jpeg', bytes));
    }
    if (!mounted) return;

    setState(() => _uploading = true);
    final uploadProvider = context.read<DocumentUploadProvider>();
    final success = await uploadProvider.upload(entries);
    if (!mounted) return;
    setState(() => _uploading = false);

    if (success) {
      await context.read<QuestionnaireProvider>().resumeAfterDocumentUpload();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(uploadProvider.errorMessage ?? 'Не удалось загрузить документ.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = widget.suggestion;

    return CenteredContent(
      child: Padding(
        padding: const EdgeInsets.all(Insets.x20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.camera_alt_outlined, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: Insets.x20),
            Text(suggestion.title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: Insets.x8),
            Text(
              suggestion.description,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Insets.x32),
            if (_uploading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFromCamera,
                      icon: const Icon(Icons.photo_camera_outlined, size: 20),
                      label: const Text('Камера'),
                    ),
                  ),
                  const SizedBox(width: Insets.x12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library_outlined, size: 20),
                      label: const Text('Галерея'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.x12),
              TextButton(
                onPressed: () => context.read<QuestionnaireProvider>().dismissDocumentSuggestion(),
                child: const Text('Продолжить без документа'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Owns its `TextEditingController` for the whole dialog route lifetime -
/// disposing it eagerly right after `showDialog` resolves (rather than
/// letting this widget's own `dispose()` do it once the exit animation
/// actually finishes) crashes the framework, because the still-animating
/// `TextField` tries to rebuild against an already-disposed controller.
class _EditFieldDialog extends StatefulWidget {
  const _EditFieldDialog({required this.label, required this.initialValue});

  final String label;
  final String initialValue;

  @override
  State<_EditFieldDialog> createState() => _EditFieldDialogState();
}

class _EditFieldDialogState extends State<_EditFieldDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.label),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 1,
        maxLines: 4,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
