import 'content_catalog.dart';
import 'quiz_catalog.dart';
import 'practice_session.dart';

List<PracticeCard> buildTopicTest(
    ContentCatalog content, QuizCatalog quizzes, String level,
    {String? topic, int maxWords = 5}) {
  final allowed =
      content.published(level, topic: topic).map((w) => w.item.id).toSet();
  final questions = {
    for (final q in quizzes.visible(level: level))
      if (allowed.contains(q.itemId)) q.itemId: q
  }.values.toList()
    ..shuffle();
  final selected = questions.take(maxWords).toList();
  return [
    for (final mode in [PracticeMode.recognition, PracticeMode.listening])
      for (final q in selected)
        PracticeCard(
            id: '${q.itemId}:${mode.name}',
            level: q.level,
            mode: mode,
            prompt: q.question,
            answer: q.options[q.correctOption],
            explanation: q.explanation,
            options: q.options,
            correctOption: q.correctOption),
  ];
}
