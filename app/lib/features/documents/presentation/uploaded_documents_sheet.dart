import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/localization/backend_phrases.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/documents/domain/uploaded_document.dart';
import 'package:app/features/documents/providers/document_upload_provider.dart';
import 'package:app/features/questionnaire/presentation/widgets/confidence_badge.dart';

/// Everything the deal knows from uploaded documents, in one place: each
/// document with its recognized fields, an edit affordance per field (a
/// misread VIN shouldn't require re-uploading) and document deletion.
/// All data and all mutations go straight through
/// [DocumentUploadProvider] - nothing document-related is decided here.
class UploadedDocumentsSheet extends StatelessWidget {
  const UploadedDocumentsSheet({super.key, this.onChanged});

  /// Fired after any successful mutation (field fix, deletion) so the
  /// caller can refresh backend-derived state (progress, review).
  final VoidCallback? onChanged;

  static Future<void> show(BuildContext context, {VoidCallback? onChanged}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UploadedDocumentsSheet(onChanged: onChanged),
    );
  }

  Future<void> _editField(BuildContext context, UploadedDocument document, String key, String value) async {
    final controller = TextEditingController(text: value);
    final newValue = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localizeDocumentFieldKey(key)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (newValue == null || newValue.isEmpty || newValue == value || !context.mounted) return;

    await context.read<DocumentUploadProvider>().updateField(document.id, key, newValue);
    onChanged?.call();
  }

  Future<void> _deleteDocument(BuildContext context, UploadedDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить документ?'),
        content: Text('«${document.fileName}» и все распознанные из него данные будут удалены из сделки.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<DocumentUploadProvider>().deleteDocument(document.id);
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Corners.x2l)),
          ),
          child: Consumer<DocumentUploadProvider>(
            builder: (context, uploads, _) {
              final documents = uploads.uploadedDocuments;
              return Column(
                children: [
                  const SizedBox(height: Insets.x12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Insets.x24, Insets.x16, Insets.x24, Insets.x8),
                    child: Row(
                      children: [
                        Icon(Icons.folder_copy_outlined, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: Insets.x8),
                        Expanded(child: Text('Загруженные документы', style: theme.textTheme.titleMedium)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: documents.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(Insets.x32),
                              child: Text(
                                'Документов пока нет. Прикрепите фото через скрепку — я заполню данные автоматически.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(Insets.x20),
                            itemCount: documents.length,
                            separatorBuilder: (_, _) => const SizedBox(height: Insets.x12),
                            itemBuilder: (context, index) => _DocumentCard(
                              document: documents[index],
                              onEditField: (key, value) => _editField(context, documents[index], key, value),
                              onDelete: () => _deleteDocument(context, documents[index]),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document, required this.onEditField, required this.onDelete});

  final UploadedDocument document;
  final void Function(String key, String value) onEditField;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: Corners.lgRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(Insets.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                document.isFailed ? Icons.error_outline_rounded : Icons.description_outlined,
                size: 20,
                color: document.isFailed ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
              const SizedBox(width: Insets.x8),
              Expanded(
                child: Text(
                  document.fileName,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                tooltip: 'Удалить документ',
                color: theme.colorScheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (document.isFailed)
            Padding(
              padding: const EdgeInsets.only(top: Insets.x4),
              child: Text(
                document.errorMessage ?? 'Не удалось распознать документ.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            )
          else if (document.mismatchWarning != null)
            Padding(
              padding: const EdgeInsets.only(top: Insets.x4),
              child: Text(
                document.mismatchWarning!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          if (document.fields.isNotEmpty) ...[
            const SizedBox(height: Insets.x8),
            for (final entry in document.fields.entries)
              InkWell(
                borderRadius: Corners.smRadius,
                onTap: () => onEditField(entry.key, entry.value.value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.x8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizeDocumentFieldKey(entry.key),
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 2),
                            Text(entry.value.value, style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 2),
                            ConfidenceBadge(confidence: entry.value.confidence),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_outlined, size: 16, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
