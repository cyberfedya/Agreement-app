/// Mirrors the backend's `DealReviewFieldDto` - one field's pre-generation
/// state as classified by `GetDealReviewUseCase`. The backend decides
/// source, confidence, status and grouping; Flutter only renders.
class DealReviewField {
  const DealReviewField({
    required this.fieldId,
    required this.label,
    required this.value,
    required this.source,
    required this.confidence,
    required this.status,
    required this.reason,
  });

  final int fieldId;
  final String label;

  /// Null for missing/skipped fields.
  final String? value;

  /// "manual" | "user_override" | "system" | a document-hint source.
  final String source;
  final double confidence;

  /// "CONFIRMED" | "AUTO_FILLED" | "CORRECTED" | "LOCKED" | "UNKNOWN".
  final String status;
  final String reason;

  factory DealReviewField.fromJson(Map<String, dynamic> json) => DealReviewField(
    fieldId: json['fieldId'] as int,
    label: json['label'] as String,
    value: json['value'] as String?,
    source: json['source'] as String,
    confidence: (json['confidence'] as num).toDouble(),
    status: json['status'] as String,
    reason: json['reason'] as String,
  );
}

class DealFieldState {
  const DealFieldState({
    required this.fieldId,
    required this.label,
    required this.value,
    required this.required,
    required this.source,
    required this.confidence,
    required this.confirmationStatus,
    required this.party,
    required this.dispute,
    required this.status,
    required this.reason,
  });

  final int fieldId;
  final String label;
  final String? value;
  final bool required;
  final String source;
  final double confidence;
  final String confirmationStatus;
  final String party;
  final bool dispute;
  final String status;
  final String reason;

  factory DealFieldState.fromJson(Map<String, dynamic> json) => DealFieldState(
    fieldId: json['fieldId'] as int,
    label: json['label'] as String,
    value: json['value'] as String?,
    required: json['required'] as bool? ?? false,
    source: json['source'] as String,
    confidence: (json['confidence'] as num).toDouble(),
    confirmationStatus: json['confirmationStatus'] as String,
    party: json['party'] as String,
    dispute: json['dispute'] as bool? ?? false,
    status: json['status'] as String,
    reason: json['reason'] as String,
  );
}

/// Mirrors the backend's `DealReviewDto`: the deterministic, read-only
/// pre-generation review, already grouped by the backend.
class DealReview {
  const DealReview({
    required this.autoFilled,
    required this.manual,
    required this.corrected,
    required this.missing,
    required this.skipped,
    required this.fieldStates,
    required this.workflowStatus,
    required this.workflowReason,
  });

  final List<DealReviewField> autoFilled;
  final List<DealReviewField> manual;
  final List<DealReviewField> corrected;
  final List<DealReviewField> missing;
  final List<DealReviewField> skipped;
  final List<DealFieldState> fieldStates;
  final String? workflowStatus;
  final String? workflowReason;

  /// How many fields the user never had to type (backend-classified).
  int get autoFilledCount => autoFilled.length + corrected.length;

  factory DealReview.fromJson(Map<String, dynamic> json) {
    List<DealReviewField> parse(String key) =>
        (json[key] as List? ?? const []).cast<Map<String, dynamic>>().map(DealReviewField.fromJson).toList();
    return DealReview(
      autoFilled: parse('autoFilled'),
      manual: parse('manual'),
      corrected: parse('corrected'),
      missing: parse('missing'),
      skipped: parse('skipped'),
      fieldStates: (json['fieldStates'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(DealFieldState.fromJson)
          .toList(),
      workflowStatus: json['workflowStatus'] as String?,
      workflowReason: json['workflowReason'] as String?,
    );
  }
}
