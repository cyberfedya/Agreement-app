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
  });

  final String id;
  final String fileName;
  final String documentType;
  final double typeConfidence;

  /// "Pending" | "Processed" | "Failed"
  final String status;
  final String? errorMessage;
  final Map<String, ExtractedField> fields;

  bool get isProcessed => status == 'Processed';
  bool get isFailed => status == 'Failed';

  factory UploadedDocument.fromJson(Map<String, dynamic> json) => UploadedDocument(
    id: json['id'] as String,
    fileName: json['fileName'] as String,
    documentType: json['documentType'] as String,
    typeConfidence: (json['typeConfidence'] as num).toDouble(),
    status: json['status'] as String,
    errorMessage: json['errorMessage'] as String?,
    fields: (json['fields'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, ExtractedField.fromJson(value as Map<String, dynamic>)),
    ),
  );
}
