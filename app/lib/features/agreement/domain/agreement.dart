class Agreement {
  const Agreement({
    required this.key,
    required this.html,
    required this.generatedAt,
    this.secondPartyName,
    this.firstPartyName,
    this.firstPartySignedAt,
    this.secondPartySignedAt,
    this.isFullySigned = false,
  });

  final String key;
  final String html;
  final DateTime generatedAt;

  /// Set once the second party has signed via the backend - null until then.
  final String? secondPartyName;

  /// Set once the first party (creator) has signed via the backend - null until then.
  final String? firstPartyName;

  final DateTime? firstPartySignedAt;
  final DateTime? secondPartySignedAt;

  /// True only once BOTH parties have signed - not just one.
  final bool isFullySigned;

  factory Agreement.fromJson(Map<String, dynamic> json) => Agreement(
    key: json['key'] as String,
    html: json['html'] as String,
    generatedAt: DateTime.parse(json['generatedAt'] as String),
    secondPartyName: json['secondPartyName'] as String?,
    firstPartyName: json['firstPartyName'] as String?,
    firstPartySignedAt: json['firstPartySignedAt'] == null
        ? null
        : DateTime.parse(json['firstPartySignedAt'] as String),
    secondPartySignedAt: json['secondPartySignedAt'] == null
        ? null
        : DateTime.parse(json['secondPartySignedAt'] as String),
    isFullySigned: json['isFullySigned'] as bool? ?? false,
  );
}
