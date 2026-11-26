import 'practice_session.dart';

/// Report the observed vocabulary sample; never infer a certified CEFR level.
class TestReport {
  final PracticeSession session;
  TestReport(this.session);
  Map<String, dynamic>? outcome(PracticeCard card) {
    for (final row in session.outcomes) {
      if (row['id'] == card.id) return row;
    }
    return null;
  }

  List<PracticeCard> get reviewNext {
    final words = <String, PracticeCard>{};
    for (final card in session.cards) {
      if (outcome(card)?['correct'] != true) words[card.answer] = card;
    }
    return words.values.toList();
  }

  String count(Iterable<PracticeCard> cards) {
    final list = cards.toList();
    final correct = list.where((c) => outcome(c)?['correct'] == true).length;
    return '$correct / ${list.length} correct';
  }

  String? get suggestedLevel {
    for (final level in ['A1', 'A2', 'B1', 'B2']) {
      final sample = session.cards.where((c) => c.level == level).toList();
      if (sample.length >= 3 &&
          sample.any((c) => outcome(c)?['correct'] != true)) return level;
    }
    return null;
  }
}
