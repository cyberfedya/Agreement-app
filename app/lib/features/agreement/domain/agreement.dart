class Agreement {
  const Agreement({required this.key, required this.html, required this.generatedAt});

  final String key;
  final String html;
  final DateTime generatedAt;

  factory Agreement.fromJson(Map<String, dynamic> json) => Agreement(
    key: json['key'] as String,
    html: json['html'] as String,
    generatedAt: DateTime.parse(json['generatedAt'] as String),
  );
}
