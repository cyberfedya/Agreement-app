import 'package:app/features/questionnaire/domain/question.dart';

/// One turn's worth of guidance from the backend's Interview Planner:
/// either "here's the next thing to ask" or "you have enough — generate".
class InterviewStep {
  const InterviewStep({required this.readyToGenerate, this.question});

  final bool readyToGenerate;
  final Question? question;

  factory InterviewStep.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 'ready_to_generate') {
      return const InterviewStep(readyToGenerate: true);
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
