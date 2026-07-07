class Question {
  const Question({
    required this.fieldId,
    required this.fieldName,
    required this.required,
    required this.type,
  });

  final int fieldId;
  final String fieldName;
  final bool required;
  final String type;

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    fieldId: json['fieldId'] as int,
    fieldName: json['fieldName'] as String,
    required: json['required'] as bool,
    type: json['type'] as String,
  );
}
