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
    this.acceptedAt,
    this.firstPartyRole,
    this.secondPartyRole,
    this.templateDomain,
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

  /// Set once the second party has accepted the invite - null until then.
  final DateTime? acceptedAt;

  /// Stable role codes (e.g. "seller"/"buyer") resolved once at generation
  /// time - drives the universal, non-hardcoded completion messaging.
  final String? firstPartyRole;
  final String? secondPartyRole;

  /// The template's domain key (e.g. "vehicle", "real_estate") - also for
  /// completion messaging.
  final String? templateDomain;

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
    acceptedAt: json['acceptedAt'] == null ? null : DateTime.parse(json['acceptedAt'] as String),
    firstPartyRole: json['firstPartyRole'] as String?,
    secondPartyRole: json['secondPartyRole'] as String?,
    templateDomain: json['templateDomain'] as String?,
  );
}
