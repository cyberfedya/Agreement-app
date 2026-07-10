class ExtractedField {
  const ExtractedField({required this.value, required this.confidence});

  final String value;
  final double confidence;

  factory ExtractedField.fromJson(Map<String, dynamic> json) =>
      ExtractedField(value: json['value'] as String, confidence: (json['confidence'] as num).toDouble());
}

class UploadedDocument {
  const UploadedDocument({
    required this.id,
    required this.fileName,
    required this.documentType,
    required this.typeConfidence,
    required this.status,
    required this.fields,
    this.errorMessage,
    this.mismatchWarning,
  });

  final String id;
  final String fileName;
  final String documentType;
  final double typeConfidence;

  /// "Pending" | "Processed" | "Failed"
  final String status;
  final String? errorMessage;

  /// Non-null when this document appears to be about a different
  /// real-world subject than what the user already told the system (e.g.
  /// a different car). The document and its fields are still saved and
  /// editable - they're just not silently used to fill the interview.
  final String? mismatchWarning;
  final Map<String, ExtractedField> fields;

  bool get isProcessed => status == 'Processed';
  bool get isFailed => status == 'Failed';

  /// Returns a copy with [key] set to a user-confirmed value (confidence
  /// 1.0 - a human just looked at the document and typed it themselves).
  UploadedDocument withField(String key, String value) {
    final updated = Map<String, ExtractedField>.from(fields);
    updated[key] = ExtractedField(value: value, confidence: 1);
    return UploadedDocument(
      id: id,
      fileName: fileName,
      documentType: documentType,
      typeConfidence: typeConfidence,
      status: status,
      errorMessage: errorMessage,
      mismatchWarning: mismatchWarning,
      fields: updated,
    );
  }

  factory UploadedDocument.fromJson(Map<String, dynamic> json) => UploadedDocument(
    id: json['id'] as String,
    fileName: json['fileName'] as String,
    documentType: json['documentType'] as String,
    typeConfidence: (json['typeConfidence'] as num).toDouble(),
    status: json['status'] as String,
    errorMessage: json['errorMessage'] as String?,
    mismatchWarning: json['mismatchWarning'] as String?,
    fields: (json['fields'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, ExtractedField.fromJson(value as Map<String, dynamic>)),
    ),
  );
}
