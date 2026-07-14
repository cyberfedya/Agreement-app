import 'package:app/features/questionnaire/domain/question.dart';

/// Which conversational stage the current question belongs to (e.g. "🚗
/// Автомобиль" or "📄 Условия сделки"), already localized by the backend.
/// Two fields with the same [key] are the same stage even across turns -
/// that's what the UI uses to detect "still in this stage" vs "just moved
/// to the next one".
class InterviewStage {
  const InterviewStage({required this.key, required this.icon, required this.label});

  final String key;
  final String icon;
  final String label;

  factory InterviewStage.fromJson(Map<String, dynamic> json) => InterviewStage(
    key: json['key'] as String,
    icon: json['icon'] as String,
    label: json['label'] as String,
  );
}

/// Non-mandatory mid-interview upload suggestion - shown instead of the
/// next question when uploading a photo would fill several fields at
/// once. [documentType] is the backend's `DocumentType` enum name (e.g.
/// `"VehicleRegistration"`) - echo it back verbatim if the user dismisses.
class DocumentSuggestion {
  const DocumentSuggestion({
    required this.documentType,
    required this.title,
    required this.description,
    required this.matchedFieldCount,
  });

  final String documentType;
  final String title;
  final String description;
  final int matchedFieldCount;

  factory DocumentSuggestion.fromJson(Map<String, dynamic> json) => DocumentSuggestion(
    documentType: json['documentType'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    matchedFieldCount: json['matchedFieldCount'] as int,
  );
}

/// One turn's worth of guidance from the backend's Interview Planner:
/// "here's the next thing to ask", "you have enough — generate", or
/// "consider uploading this document before we keep going".
class InterviewStep {
  const InterviewStep({
    required this.readyToGenerate,
    this.question,
    this.closingMessage,
    this.documentSuggestion,
    this.stage,
  });

  final bool readyToGenerate;
  final Question? question;
  final DocumentSuggestion? documentSuggestion;
  final InterviewStage? stage;

  /// Short spoken/shown sign-off for when [readyToGenerate] is true — e.g.
  /// "Спасибо. Этой информации уже достаточно, чтобы подготовить проект
  /// договора." Null for a "need more info" step.
  final String? closingMessage;

  factory InterviewStep.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 'suggest_document') {
      return InterviewStep(
        readyToGenerate: false,
        documentSuggestion: DocumentSuggestion.fromJson(json['documentSuggestion'] as Map<String, dynamic>),
      );
    }
    if (json['status'] == 'ready_to_generate') {
      return InterviewStep(readyToGenerate: true, closingMessage: json['nextQuestion'] as String?);
    }
    return InterviewStep(
      readyToGenerate: false,
      question: Question(
        fieldId: json['nextFieldId'] as int,
        fieldName: json['nextQuestion'] as String,
        required: true,
        type: 'text',
      ),
      stage: json['stage'] != null ? InterviewStage.fromJson(json['stage'] as Map<String, dynamic>) : null,
    );
  }
}
