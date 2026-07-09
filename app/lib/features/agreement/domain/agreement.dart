class Agreement {
  const Agreement({required this.key, required this.html, required this.generatedAt, this.secondPartyName});

  final String key;
  final String html;
  final DateTime generatedAt;

  /// Set once the second party has signed via the backend - null until then.
  final String? secondPartyName;

  factory Agreement.fromJson(Map<String, dynamic> json) => Agreement(
    key: json['key'] as String,
    html: json['html'] as String,
    generatedAt: DateTime.parse(json['generatedAt'] as String),
    secondPartyName: json['secondPartyName'] as String?,
  );
}
