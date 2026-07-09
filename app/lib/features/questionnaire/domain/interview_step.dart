import 'package:app/features/questionnaire/domain/question.dart';

/// One turn's worth of guidance from the backend's Interview Planner:
/// either "here's the next thing to ask" or "you have enough — generate".
class InterviewStep {
  const InterviewStep({required this.readyToGenerate, this.question, this.closingMessage});

  final bool readyToGenerate;
  final Question? question;

  /// Short spoken/shown sign-off for when [readyToGenerate] is true — e.g.
  /// "Спасибо. Этой информации уже достаточно, чтобы подготовить проект
  /// договора." Null for a "need more info" step.
  final String? closingMessage;

  factory InterviewStep.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
