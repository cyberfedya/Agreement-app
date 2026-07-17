import 'package:flutter/material.dart';

import 'package:app/l10n/app_localizations.dart';

/// Owns its `TextEditingController` for the whole dialog route lifetime -
/// disposing it eagerly right after `showDialog` resolves (rather than
/// letting this widget's own `dispose()` do it once the exit animation
/// actually finishes) crashes the framework, because the still-animating
/// `TextField` tries to rebuild against an already-disposed controller.
class EditFieldDialog extends StatefulWidget {
  const EditFieldDialog({super.key, required this.label, required this.initialValue});

  final String label;
  final String initialValue;

  @override
  State<EditFieldDialog> createState() => _EditFieldDialogState();
}

class _EditFieldDialogState extends State<EditFieldDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
