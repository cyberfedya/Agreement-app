enum DealStatus { draft, pendingSignature, completed }

/// A single agreement-creation session, identified once the backend has
/// matched (or been told) which template it's for. The interview flow is
/// keyed by [id] — no screen navigates using a bare template key anymore.
class Deal {
  const Deal({
    required this.id,
    required this.templateKey,
    required this.templateTitle,
    required this.status,
  });

  final String id;
  final String templateKey;
  final String templateTitle;
  final DealStatus status;

  factory Deal.fromJson(Map<String, dynamic> json) => Deal(
    id: json['id'] as String,
    templateKey: json['templateKey'] as String,
    templateTitle: json['templateTitle'] as String,
    status: _statusFromJson(json['status'] as String),
  );

  static DealStatus _statusFromJson(String value) => switch (value) {
    'Draft' => DealStatus.draft,
    'Completed' => DealStatus.completed,
    _ => DealStatus.draft,
  };
}
