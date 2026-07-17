import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// Multi-page camera capture: unlike a single `pickImage` call, this lets
/// the user take as many pages of one document as they need, retake any
/// individual page, delete one, then confirm the whole batch at once - the
/// same freedom the gallery's native multi-select already gives, just for
/// the camera. Returns the final list of pages (empty if the user backs out
/// without keeping any).
class CameraCaptureSheet extends StatefulWidget {
  const CameraCaptureSheet({super.key});

  static Future<List<XFile>> show(BuildContext context) async {
    final result = await Navigator.of(
      context,
    ).push<List<XFile>>(MaterialPageRoute(builder: (_) => const CameraCaptureSheet(), fullscreenDialog: true));
    return result ?? [];
  }

  @override
  State<CameraCaptureSheet> createState() => _CameraCaptureSheetState();
}

class _CameraCaptureSheetState extends State<CameraCaptureSheet> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _pages = [];
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    // Opening this screen should jump straight into the camera, same as
    // the old single-shot flow - no extra tap to get started.
    WidgetsBinding.instance.addPostFrameCallback((_) => _takePhoto());
  }

  Future<void> _takePhoto({int? replaceIndex}) async {
    if (_capturing) return;
    setState(() => _capturing = true);
    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (!mounted) return;
    setState(() {
      _capturing = false;
      if (file == null) return;
      if (replaceIndex != null) {
        _pages[replaceIndex] = file;
      } else {
        _pages.add(file);
      }
    });

    // The very first shot was canceled and nothing was kept - there's
    // nothing useful to show, so leave the same way a single-shot camera
    // pick that was canceled always did.
    if (file == null && replaceIndex == null && _pages.isEmpty) {
      Navigator.of(context).pop(<XFile>[]);
    }
  }

  void _delete(int index) {
    HapticFeedback.selectionClick();
    setState(() => _pages.removeAt(index));
  }

  void _done() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_pages);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.documentCaptureTitle),
        actions: [
          if (_pages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.x8),
              child: Center(
                child: Text('${_pages.length}', style: theme.textTheme.titleSmall),
              ),
            ),
        ],
      ),
      body: _pages.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Insets.x32),
                child: Text(
                  l10n.documentCaptureEmptyHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(Insets.x16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: Insets.x12,
                crossAxisSpacing: Insets.x12,
                childAspectRatio: 0.72,
              ),
              itemCount: _pages.length + 1,
              itemBuilder: (context, index) {
                if (index == _pages.length) {
                  return _AddPageTile(onTap: _capturing ? null : () => _takePhoto());
                }
                return _PageThumbnail(
                  file: _pages[index],
                  pageNumber: index + 1,
                  onRetake: _capturing ? null : () => _takePhoto(replaceIndex: index),
                  onDelete: () => _delete(index),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(Insets.x20),
        child: PrimaryButton(
          label: l10n.documentCaptureContinue,
          onPressed: _pages.isEmpty ? null : _done,
        ),
      ),
    );
  }
}

class _PageThumbnail extends StatelessWidget {
  const _PageThumbnail({
    required this.file,
    required this.pageNumber,
    required this.onRetake,
    required this.onDelete,
  });

  final XFile file;
  final int pageNumber;
  final VoidCallback? onRetake;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: Corners.mdRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(file.path), fit: BoxFit.cover),
          Positioned(
            left: Insets.x8,
            top: Insets.x8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Insets.x8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$pageNumber', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white)),
            ),
          ),
          Positioned(
            right: Insets.x4,
            top: Insets.x4,
            child: Row(
              children: [
                _OverlayIconButton(icon: Icons.refresh_rounded, tooltip: l10n.documentCaptureRetake, onTap: onRetake),
                const SizedBox(width: Insets.x4),
                _OverlayIconButton(icon: Icons.delete_outline_rounded, tooltip: l10n.commonDelete, onTap: onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.white),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _AddPageTile extends StatelessWidget {
  const _AddPageTile({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: Corners.mdRadius,
      child: InkWell(
        borderRadius: Corners.mdRadius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: Corners.mdRadius,
            border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 28, color: theme.colorScheme.primary),
              const SizedBox(height: Insets.x8),
              Text(
                l10n.documentCaptureAddPage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
