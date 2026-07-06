import 'package:flutter/material.dart';
import 'package:app/features/questionnaire/domain/question.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(title: Text(question.text)));
  }
}
