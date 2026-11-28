import 'package:flutter/services.dart' show rootBundle;
import 'data/content_catalog.dart';
import 'data/quiz_catalog.dart';
import 'data/practice_session.dart';

class GermanQuiz {
  final String Questions, explanation, itemId, level;
  final List<String> Options;
  final int CorrectOption;
  GermanQuiz.fromItem(QuizItem item)
      : Questions = item.question,
        Options = item.options,
        CorrectOption = item.correctOption,
        explanation = item.explanation,
        itemId = item.itemId,
        level = item.level;
}

List<GermanQuiz> QuizData = [];

/// A balanced small vocabulary sample, not a CEFR placement assessment.
List<PracticeCard> buildQuickVocabularyCheck(List<GermanQuiz> questions) {
  final cards = <PracticeCard>[];
  for (final level in ['A1', 'A2', 'B1', 'B2']) {
    final pool = {
      for (final q in questions)
        if (q.level == level) q.itemId: q
    }.values.toList()
      ..shuffle();
    if (pool.length < 3) return [];
    for (final q in pool.take(3)) {
      cards.add(PracticeCard(
          id: q.itemId,
          level: q.level,
          prompt: q.Questions,
          answer: q.Options[q.CorrectOption],
          explanation: q.explanation,
          options: q.Options,
          correctOption: q.CorrectOption));
    }
  }
  return cards;
}

Future<List<GermanQuiz>> loadQuizData() async {
  final content = ContentCatalog.decode(
      await rootBundle.loadString('assets/content_catalog_v1.json'));
  final quizzes = QuizCatalog.decode(
      await rootBundle.loadString('assets/quiz_catalog_v1.json'), content);
  QuizData = quizzes.visible().map(GermanQuiz.fromItem).toList(growable: false);
  return QuizData;
}
