import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/documents/data/document_repository.dart';
import 'package:app/features/documents/presentation/document_capture.dart';
import 'package:app/features/documents/domain/document_verification.dart';
import 'package:app/features/documents/providers/document_upload_provider.dart';
import 'package:app/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/shared/animation/entrance.dart';
import 'package:app/shared/models/result.dart';
import 'package:app/shared/utils/image_format.dart';
import 'package:app/shared/widgets/primary_button.dart';

enum _Phase { prompt, working, conflicts, done }
class DocumentVerificationView extends StatefulWidget {
  const DocumentVerificationView({super.key, required this.dealId, required this.onFinished});

  final String dealId;
  final VoidCallback onFinished;

  @override
  State<DocumentVerificationView> createState() => _DocumentVerificationViewState();
}

class _DocumentVerificationViewState extends State<DocumentVerificationView> {
  _Phase _phase = _Phase.prompt;
  List<DocumentFieldConflict> _conflicts = const [];
  int _conflictIndex = 0;
  String? _errorMessage;
  String? _conflictError;

  Future<void> _upload(
    List<(String fileName, String contentType, List<int> bytes)> files,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _phase = _Phase.working;
      _errorMessage = null;
    });

    final uploaded = await context.read<DocumentUploadProvider>().upload(files);
    if (!mounted) return;
    if (!uploaded) {
      setState(() {
        _phase = _Phase.prompt;
        _errorMessage = context.read<DocumentUploadProvider>().errorMessage ?? l10n.commonUploadFailed;
      });
      return;
    }

    final result = await context.read<DocumentRepository>().verifyDocument(widget.dealId);
    if (!mounted) return;

    switch (result) {
      case Success(value: final verification):
        _applyVerification(verification);
      case Failure():
        setState(() {
          _phase = _Phase.prompt;
          _errorMessage = l10n.documentVerificationCompareFailed;
        });
    }
  }

  void _applyVerification(DocumentVerification verification) {
    if (!verification.hasConflicts) {
      setState(() => _phase = _Phase.done);
      return;
    }
    setState(() {
      _conflicts = verification.conflicts;
      _conflictIndex = 0;
      _conflictError = null;
      _phase = _Phase.conflicts;
    });
  }

  Future<void> _resolveConflict({required bool useDocumentValue}) async {
    final conflict = _conflicts[_conflictIndex];
    if (useDocumentValue) {
      final saved = await context
          .read<QuestionnaireProvider>()
          .editAnswer(conflict.fieldId, conflict.label, conflict.documentValue);
      if (!mounted) return;
      if (!saved) {
        setState(() => _conflictError = AppLocalizations.of(context)!.documentVerificationConflictRetryError);
        return;
      }
    }

    if (_conflictIndex + 1 >= _conflicts.length) {
      widget.onFinished();
    } else {
      setState(() {
        _conflictIndex += 1;
        _conflictError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.prompt => _PromptView(errorMessage: _errorMessage, onUpload: _upload),
      _Phase.working => const _WorkingView(),
      _Phase.conflicts => _ConflictView(
        conflict: _conflicts[_conflictIndex],
        position: _conflictIndex + 1,
        total: _conflicts.length,
        errorMessage: _conflictError,
        onUseDocumentValue: () => _resolveConflict(useDocumentValue: true),
        onKeepMine: () => _resolveConflict(useDocumentValue: false),
      ),
      _Phase.done => _DoneView(onContinue: widget.onFinished),
    };
  }
}

class _PromptView extends StatelessWidget {
  const _PromptView({required this.errorMessage, required this.onUpload});

  final String? errorMessage;
  final Future<void> Function(List<(String fileName, String contentType, List<int> bytes)> files) onUpload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Insets.x24, Insets.x24, Insets.x24, Insets.x32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Insets.x24),
          Center(
            child: Container(
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
                  decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primaryContainer),
                  child: Icon(Icons.document_scanner_outlined, size: 38, color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
            ),
          ).animateEntrance(),
          const SizedBox(height: Insets.x32),
          Text(
            l10n.documentVerificationTitle,
            style: theme.textTheme.headlineSmall?.copyWith(height: 1.25),
            textAlign: TextAlign.center,
          ).animateEntranceStaggered(1),
          const SizedBox(height: Insets.x12),
          Text(
            l10n.documentVerificationBody,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ).animateEntranceStaggered(2),
          if (errorMessage != null) ...[
            const SizedBox(height: Insets.x16),
            Text(
              errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: Insets.x40),
          PrimaryButton(
            label: l10n.documentVerificationUploadButton,
            icon: Icons.photo_camera_outlined,
            onPressed: () => _pick(context, onUpload),
          ).animateEntranceStaggered(3),
        ],
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    Future<void> Function(List<(String fileName, String contentType, List<int> bytes)> files) onUpload,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.xl))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Insets.x8),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.commonCamera),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.commonGallery),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    final picked = await pickDocumentFiles(context, source);
    if (picked.isEmpty || !context.mounted) return;

    final entries = <(String, String, List<int>)>[];
    for (final file in picked) {
      final bytes = await file.readAsBytes();
      final contentType = sniffImageContentType(bytes);
      if (contentType == null) continue;
      entries.add((normalizedFileName(file.name, contentType), contentType, bytes));
    }
    if (entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.commonUnsupportedPhotoFormat)));
      }
      return;
    }

    await onUpload(entries);
  }
}

class _WorkingView extends StatelessWidget {
  const _WorkingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('verification-working'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: Insets.x16),
          Text(AppLocalizations.of(context)!.documentVerificationWorking),
        ],
      ),
    );
  }
}

class _ConflictView extends StatelessWidget {
  const _ConflictView({
    required this.conflict,
    required this.position,
    required this.total,
    required this.errorMessage,
    required this.onUseDocumentValue,
    required this.onKeepMine,
  });

  final DocumentFieldConflict conflict;
  final int position;
  final int total;
  final String? errorMessage;
  final VoidCallback onUseDocumentValue;
  final VoidCallback onKeepMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      key: ValueKey('conflict-${conflict.fieldId}'),
      padding: const EdgeInsets.fromLTRB(Insets.x24, Insets.x24, Insets.x24, Insets.x32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (total > 1)
            Text(
              l10n.documentVerificationConflictPosition(position, total),
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline),
            ),
          const SizedBox(height: Insets.x8),
          Text(l10n.documentVerificationConflictTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Insets.x8),
          Text(conflict.label, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: Insets.x24),
          _ValueCard(label: l10n.documentVerificationYouEntered, value: conflict.userValue, theme: theme),
          const SizedBox(height: Insets.x12),
          _ValueCard(
            label: l10n.documentVerificationInDocument,
            value: conflict.documentValue,
            theme: theme,
            highlight: true,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: Insets.x16),
            Text(
              errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: Insets.x32),
          PrimaryButton(label: l10n.documentVerificationUseDocumentValue, onPressed: onUseDocumentValue),
          const SizedBox(height: Insets.x8),
          OutlinedButton(onPressed: onKeepMine, child: Text(l10n.documentVerificationKeepMine)),
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.label, required this.value, required this.theme, this.highlight = false});

  final String label;
  final String value;
  final ThemeData theme;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.x16),
      decoration: BoxDecoration(
        color: highlight ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4) : theme.colorScheme.surfaceContainerLow,
        borderRadius: Corners.lgRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: Insets.x4),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DoneView extends StatefulWidget {
  const _DoneView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<_DoneView> createState() => _DoneViewState();
}

class _DoneViewState extends State<_DoneView> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) widget.onContinue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      key: const ValueKey('verification-done'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.x24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 40, color: theme.colorScheme.primary).animateEntrance(),
            const SizedBox(height: Insets.x12),
            Text(
              l10n.documentVerificationDoneTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ).animateEntranceStaggered(1),
            const SizedBox(height: Insets.x4),
            Text(
              l10n.documentVerificationDoneBody,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ).animateEntranceStaggered(2),
          ],
        ),
      ),
    );
  }
}
