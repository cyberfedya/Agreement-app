/// One field where what the user typed during the interview disagrees
/// with what the final document check found. Never sent for a field the
/// user simply never answered - those are filled in silently on the
/// backend, invisible to this screen by design.
class DocumentFieldConflict {
  const DocumentFieldConflict({
    required this.fieldId,
    required this.label,
    required this.userValue,
    required this.documentValue,
  });

  final int fieldId;
  final String label;
  final String userValue;
  final String documentValue;

  factory DocumentFieldConflict.fromJson(Map<String, dynamic> json) => DocumentFieldConflict(
    fieldId: json['fieldId'] as int,
    label: json['label'] as String,
    userValue: json['userValue'] as String,
    documentValue: json['documentValue'] as String,
  );
}

/// Result of the final, optional "check the document" step.
class DocumentVerification {
  const DocumentVerification({required this.conflicts});

  final List<DocumentFieldConflict> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;

  factory DocumentVerification.fromJson(Map<String, dynamic> json) => DocumentVerification(
    conflicts: (json['conflicts'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(DocumentFieldConflict.fromJson)
        .toList(),
  );
}
