import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'data/content_catalog.dart';
import 'data/quiz_catalog.dart';

class GermanQuiz {
  final String Questions, explanation, itemId;
  final List<String> Options;
  final int CorrectOption;
  GermanQuiz.fromItem(QuizItem item)
      : Questions = item.question,
        Options = item.options,
        CorrectOption = item.correctOption,
        explanation = item.explanation,
        itemId = item.itemId;
}

List<GermanQuiz> QuizData = [];

Future<List<GermanQuiz>> loadQuizData() async {
  final content = ContentCatalog.decode(
      await rootBundle.loadString('assets/content_catalog_v1.json'));
  final quizzes = QuizCatalog.decode(
      await rootBundle.loadString('assets/quiz_catalog_v1.json'), content);
  QuizData = quizzes
      .visible(includeDrafts: kDebugMode)
      .map(GermanQuiz.fromItem)
      .toList(growable: false);
  return QuizData;
}
