import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/questionnaire/data/questionnaire_repository.dart';
import 'package:app/features/questionnaire/domain/deal_review.dart';
import 'package:app/shared/models/result.dart';

/// What the second party wants changed: one field, a counter-value, and
/// an optional explanation. Returned by [ProposeChangeSheet].
class FieldChangeProposal {
  const FieldChangeProposal({required this.fieldId, required this.label, required this.proposedValue, this.reason});

  final int fieldId;
  final String label;
  final String proposedValue;
  final String? reason;
}

/// Two-step "предложить изменение" sheet for the second party: pick one
/// of the deal's current terms (loaded from the backend's field states -
/// never a locally-invented list), then enter a counter-value and an
/// optional reason. Pops with a [FieldChangeProposal] or null.
class ProposeChangeSheet extends StatefulWidget {
  const ProposeChangeSheet({super.key, required this.dealId});

  final String dealId;

  static Future<FieldChangeProposal?> show(BuildContext context, {required String dealId}) {
    return showModalBottomSheet<FieldChangeProposal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.xl)),
      ),
      builder: (_) => ProposeChangeSheet(dealId: dealId),
    );
  }

  @override
  State<ProposeChangeSheet> createState() => _ProposeChangeSheetState();
}

class _ProposeChangeSheetState extends State<ProposeChangeSheet> {
  final _valueController = TextEditingController();
  final _reasonController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<DealFieldState> _fields = const [];
  DealFieldState? _selected;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    switch (await context.read<QuestionnaireRepository>().getReview(widget.dealId)) {
      case Success(:final value):
        if (!mounted) return;
        setState(() {
          // Only terms that actually have a value can be countered.
          _fields = value.fieldStates.where((f) => (f.value ?? '').trim().isNotEmpty).toList();
          _loading = false;
        });
      case Failure(:final message):
        if (!mounted) return;
        setState(() {
          _error = message;
          _loading = false;
        });
    }
  }

  void _submit() {
    final selected = _selected;
    final proposedValue = _valueController.text.trim();
    if (selected == null || proposedValue.isEmpty) return;
    final reason = _reasonController.text.trim();
    Navigator.pop(
      context,
      FieldChangeProposal(
        fieldId: selected.fieldId,
        label: selected.label,
        proposedValue: proposedValue,
        reason: reason.isEmpty ? null : reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Insets.x24, Insets.x24, Insets.x24, Insets.x24),
            child: _selected == null ? _buildFieldPicker(theme) : _buildProposalForm(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldPicker(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Что хотите изменить?', style: theme.textTheme.titleLarge),
        const SizedBox(height: Insets.x8),
        Text(
          'Выберите условие договора — ваше предложение увидит вторая сторона.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: Insets.x16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Insets.x32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Insets.x24),
            child: Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
          )
        else if (_fields.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Insets.x24),
            child: Text(
              'Пока нет условий, которые можно изменить.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _fields.length,
              separatorBuilder: (_, _) => const SizedBox(height: Insets.x8),
              itemBuilder: (context, index) {
                final field = _fields[index];
                return Material(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: Corners.mdRadius,
                  child: InkWell(
                    borderRadius: Corners.mdRadius,
                    onTap: () => setState(() => _selected = field),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field.label,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 2),
                                Text(field.value ?? '', style: theme.textTheme.titleSmall),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 20, color: theme.colorScheme.outline),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProposalForm(ThemeData theme) {
    final selected = _selected!;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _selected = null),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                tooltip: 'К списку условий',
              ),
              Expanded(child: Text(selected.label, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: Insets.x8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: Corners.mdRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Сейчас в договоре', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 2),
                Text(selected.value ?? '', style: theme.textTheme.titleSmall),
              ],
            ),
          ),
          const SizedBox(height: Insets.x16),
          TextField(
            controller: _valueController,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Ваше предложение…'),
          ),
          const SizedBox(height: Insets.x12),
          TextField(
            controller: _reasonController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Почему? (необязательно)'),
          ),
          const SizedBox(height: Insets.x16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _valueController.text.trim().isEmpty ? null : _submit,
              child: const Text('Отправить предложение'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple free-form "задать вопрос" sheet. Pops with the message or null.
class ClarificationSheet extends StatefulWidget {
  const ClarificationSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.xl)),
      ),
      builder: (_) => const ClarificationSheet(),
    );
  }

  @override
  State<ClarificationSheet> createState() => _ClarificationSheetState();
}

class _ClarificationSheetState extends State<ClarificationSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Insets.x24,
          Insets.x24,
          Insets.x24,
          Insets.x24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Задать вопрос', style: theme.textTheme.titleLarge),
            const SizedBox(height: Insets.x8),
            Text(
              'Спросите то, что хотите уточнить перед подписанием — вопрос увидит вторая сторона.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: Insets.x16),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Ваш вопрос…'),
            ),
            const SizedBox(height: Insets.x16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _controller.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(context, _controller.text.trim()),
                child: const Text('Отправить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
