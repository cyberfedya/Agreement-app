import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/services/tts_service.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/features/documents/domain/required_document.dart';
import 'package:app/features/documents/domain/uploaded_document.dart';
import 'package:app/features/documents/providers/document_upload_provider.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// Shown right after a template is matched, before the interview: lets
/// the user upload photos/scans of supporting documents (never identity
/// documents - those come from the profile) so the AI can fill as many
/// fields as possible before asking anything.
class DocumentUploadPage extends StatefulWidget {
  const DocumentUploadPage({super.key, required this.dealId, required this.templateTitle});

  final String dealId;
  final String templateTitle;

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  final _picker = ImagePicker();

  // Cached rather than looked up via context.read() in dispose(): by then
  // the element is deactivated and ancestor lookups are unsafe.
  DocumentUploadProvider? _provider;
  TtsService? _tts;
  int _lastSpokenDocumentCount = 0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DocumentUploadProvider>();
    Future.microtask(() => provider.loadRequirements(widget.dealId));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tts = context.read<TtsService>();
    final provider = context.read<DocumentUploadProvider>();
    if (!identical(_provider, provider)) {
      _provider?.removeListener(_onProviderChanged);
      _provider = provider..addListener(_onProviderChanged);
    }
  }

  @override
  void dispose() {
    _tts?.stop();
    _provider?.removeListener(_onProviderChanged);
    super.dispose();
  }

  /// Speaks a short summary of what got recognized once the preview count
  /// lands after a fresh upload batch - the AI "explaining itself" instead
  /// of silently filling fields in the background.
  void _onProviderChanged() {
    final provider = _provider;
    if (provider == null || provider.isLoadingPreview) return;
    final preview = provider.preview;
    if (preview == null) return;

    final docCount = provider.uploadedDocuments.length;
    if (docCount == _lastSpokenDocumentCount) return;
    _lastSpokenDocumentCount = docCount;

    final recognized = provider.uploadedDocuments.where((d) => d.isProcessed).length;
    final remaining = preview.estimatedRemainingQuestions;
    final summary = remaining == 0
        ? 'Готово. Распознано документов: $recognized. Извлечено ${provider.extractedFieldCount} '
              'полей автоматически — этого достаточно, дополнительных вопросов не будет.'
        : 'Готово. Распознано документов: $recognized. Извлечено ${provider.extractedFieldCount} '
              'полей автоматически. Осталось уточнить ещё ${_questionsWord(remaining)}.';
    _tts?.speak(summary);
  }

  static String _questionsWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    final word = (mod10 == 1 && mod100 != 11)
        ? 'вопрос'
        : (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20))
        ? 'вопроса'
        : 'вопросов';
    return '$count $word';
  }

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

    final provider = context.read<DocumentUploadProvider>();
    final success = await provider.upload(entries);
    if (!mounted || success) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Не удалось загрузить документ.')));
  }

  void _continue() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.questionnaire,
      arguments: QuestionnaireRouteArgs(dealId: widget.dealId, templateTitle: widget.templateTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Документы')),
      body: SafeArea(
        child: Consumer<DocumentUploadProvider>(
          builder: (context, provider, _) {
            return CenteredContent(
              child: ListView(
                padding: const EdgeInsets.all(Insets.x20),
                children: [
                  Text(
                    'Чтобы сэкономить ваше время, загрузите фото или сканы связанных документов. '
                    'Я автоматически заполню всё, что смогу прочитать, и спрошу только то, чего не хватает.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                  ),
                  const SizedBox(height: Insets.x24),

                  if (provider.uploadedDocuments.isNotEmpty) ...[
                    _ExtractionSummaryCard(provider: provider),
                    const SizedBox(height: Insets.x16),
                    ...provider.uploadedDocuments.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: Insets.x8),
                        child: _UploadedDocumentCard(
                          document: d,
                          onDelete: () => provider.deleteDocument(d.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: Insets.x16),
                  ],

                  if (!provider.isLoadingRequirements && provider.requiredDocuments.isNotEmpty) ...[
                    Text('Что может пригодиться', style: theme.textTheme.labelLarge),
                    const SizedBox(height: Insets.x8),
                    ...provider.requiredDocuments.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: Insets.x8),
                        child: _SuggestedDocumentCard(document: d),
                      ),
                    ),
                    const SizedBox(height: Insets.x16),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: provider.isUploading ? null : _pickFromCamera,
                          icon: const Icon(Icons.photo_camera_outlined, size: 20),
                          label: const Text('Камера'),
                        ),
                      ),
                      const SizedBox(width: Insets.x12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: provider.isUploading ? null : _pickFromGallery,
                          icon: const Icon(Icons.photo_library_outlined, size: 20),
                          label: const Text('Галерея'),
                        ),
                      ),
                    ],
                  ),
                  if (provider.isUploading) ...[
                    const SizedBox(height: Insets.x20),
                    const Center(child: _ProcessingIndicator()),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(label: 'Продолжить', onPressed: _continue),
            TextButton(onPressed: _continue, child: const Text('Пропустить этот шаг')),
          ],
        ),
      ),
    );
  }
}

class _ProcessingIndicator extends StatelessWidget {
  const _ProcessingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4)),
        const SizedBox(width: Insets.x12),
        Text('Обрабатываю документы…', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ExtractionSummaryCard extends StatelessWidget {
  const _ExtractionSummaryCard({required this.provider});

  final DocumentUploadProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final processed = provider.uploadedDocuments.where((d) => d.isProcessed).toList();
    final failed = provider.uploadedDocuments.where((d) => d.isFailed).length;
    final preview = provider.preview;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.x16),
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: Corners.lgRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final doc in processed)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.x4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: Insets.x8),
                  Expanded(
                    child: Text(
                      '${documentTypeLabel(doc.documentType)} распознан',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          if (failed > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.x4),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: Insets.x8),
                  Text(
                    'Не удалось обработать: $failed',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Insets.x8),
          Text(
            'Извлечено автоматически: ${provider.extractedFieldCount} полей',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (provider.isLoadingPreview)
            Padding(
              padding: const EdgeInsets.only(top: Insets.x4),
              child: Text(
                'Считаю, сколько ещё нужно уточнить…',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
            )
          else if (preview != null)
            Padding(
              padding: const EdgeInsets.only(top: Insets.x4),
              child: Text(
                preview.estimatedRemainingQuestions == 0
                    ? 'Дополнительных вопросов не будет'
                    : 'Осталось уточнить: ${preview.estimatedRemainingQuestions}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
        ],
      ),
    );
  }
}

class _UploadedDocumentCard extends StatelessWidget {
  const _UploadedDocumentCard({required this.document, required this.onDelete});

  final UploadedDocument document;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Insets.x16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: Corners.lgRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            document.isProcessed
                ? Icons.check_circle_outline
                : document.isFailed
                ? Icons.error_outline
                : Icons.hourglass_top_rounded,
            color: document.isFailed ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
          const SizedBox(width: Insets.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(documentTypeLabel(document.documentType), style: theme.textTheme.titleSmall),
                Text(
                  document.isFailed
                      ? 'Не удалось распознать'
                      : '${document.fields.length} полей найдено',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            tooltip: 'Удалить и загрузить заново',
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _SuggestedDocumentCard extends StatelessWidget {
  const _SuggestedDocumentCard({required this.document});

  final RequiredDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Insets.x16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: Corners.lgRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: Insets.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(document.title, style: theme.textTheme.titleSmall),
                Text(
                  document.description,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (!document.required)
            Padding(
              padding: const EdgeInsets.only(left: Insets.x8),
              child: Text(
                'если есть',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

String documentTypeLabel(String type) => switch (type) {
  'Passport' => 'Паспорт',
  'Cadastre' => 'Кадастровый документ',
  'TechnicalPassport' => 'Технический паспорт',
  'OwnershipCertificate' => 'Свидетельство о собственности',
  'VehicleRegistration' => 'Техпаспорт автомобиля',
  'VehiclePassport' => 'ПТС',
  'CompanyRegistration' => 'Регистрационные документы компании',
  'TaxCertificate' => 'Справка налогового учёта',
  'Diploma' => 'Диплом',
  'PowerOfAttorney' => 'Доверенность',
  'Invoice' => 'Счёт/расписка',
  'BankStatement' => 'Банковская выписка',
  'EmploymentContract' => 'Трудовой документ',
  'Certificate' => 'Справка',
  'SupportingDocument' => 'Сопутствующий документ',
  _ => 'Документ',
};
