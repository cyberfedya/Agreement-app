class Question {
  const Question({
    required this.fieldId,
    required this.fieldName,
    required this.required,
    required this.type,
    this.groupFieldIds = const [],
  });

  final int fieldId;
  final String fieldName;
  final bool required;
  final String type;

  /// Every field id this question's group covers (e.g. VIN + engine + body
  /// + chassis), so the UI can render one box per field instead of a
  /// single blob. Empty means "just this field" - use [effectiveGroupFieldIds]
  /// rather than reading this directly.
  final List<int> groupFieldIds;

  /// [groupFieldIds], normalized so callers never have to special-case the
  /// empty-list default (from hand-built fixtures) or a legacy/absent
  /// backend field.
  List<int> get effectiveGroupFieldIds => groupFieldIds.isEmpty ? [fieldId] : groupFieldIds;

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    fieldId: json['fieldId'] as int,
    fieldName: json['fieldName'] as String,
    required: json['required'] as bool,
    type: json['type'] as String,
    groupFieldIds: (json['groupFieldIds'] as List?)?.cast<int>() ?? const [],
  );
}
