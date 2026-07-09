class InterviewPreview {
  const InterviewPreview({required this.totalAskableFields, required this.estimatedRemainingQuestions});

  final int totalAskableFields;
  final int estimatedRemainingQuestions;

  factory InterviewPreview.fromJson(Map<String, dynamic> json) => InterviewPreview(
    totalAskableFields: json['totalAskableFields'] as int,
    estimatedRemainingQuestions: json['estimatedRemainingQuestions'] as int,
  );
}
