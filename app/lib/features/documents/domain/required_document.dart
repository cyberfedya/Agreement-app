class RequiredDocument {
  const RequiredDocument({
    required this.type,
    required this.title,
    required this.description,
    required this.required,
    required this.priority,
  });

  final String type;
  final String title;
  final String description;
  final bool required;
  final int priority;

  factory RequiredDocument.fromJson(Map<String, dynamic> json) => RequiredDocument(
    type: json['type'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    required: json['required'] as bool,
    priority: json['priority'] as int,
  );
}
