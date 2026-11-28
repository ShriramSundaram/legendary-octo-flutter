enum PracticeMode { recognition, recall, listening }

class PracticeCard {
  final String id, prompt, answer, explanation;
  final String level;
  final PracticeMode mode;
  final List<String> options;
  final int correctOption;
  const PracticeCard(
      {required this.id,
      required this.prompt,
      required this.answer,
      required this.explanation,
      this.level = '',
      this.mode = PracticeMode.recognition,
      this.options = const [],
      this.correctOption = 0});
}

/// Only submitted choices count. Self-rated recall is reported separately.
class PracticeSession {
  final List<PracticeCard> cards;
  final Duration? limit;
  final Stopwatch clock;
  int index = 0, correct = 0, wrong = 0, remembered = 0, again = 0;
  int? selection;
  final List<Map<String, dynamic>> outcomes = [];
  bool started = false, feedback = false, complete = false, timedOut = false;
  PracticeSession(List<PracticeCard> cards, {this.limit, Stopwatch? clock})
      : cards = List.unmodifiable(cards),
        clock = clock ?? Stopwatch();
  PracticeCard get card => cards[index];
  int get scoredTotal =>
      cards.where((c) => c.mode != PracticeMode.recall).length;
  int get recallTotal => cards.length - scoredTotal;
  int get unanswered => scoredTotal - correct - wrong;
  int get unrated => recallTotal - remembered - again;
  Duration? get remaining => limit == null
      ? null
      : (limit! - clock.elapsed).isNegative
          ? Duration.zero
          : limit! - clock.elapsed;
  void start() {
    if (started || cards.isEmpty) return;
    started = true;
    clock.start();
  }

  void checkTime() {
    if (started &&
        !complete &&
        !feedback &&
        limit != null &&
        clock.elapsed >= limit!) {
      timedOut = complete = true;
      clock.stop();
    }
  }

  void select(int value) {
    checkTime();
    if (!started ||
        complete ||
        feedback ||
        value < 0 ||
        value >= card.options.length) return;
    selection = value;
  }

  void submit() {
    checkTime();
    if (!started ||
        complete ||
        feedback ||
        selection == null ||
        card.mode == PracticeMode.recall) return;
    if (selection == card.correctOption) {
      correct++;
    } else {
      wrong++;
    }
    outcomes.add({
      'id': card.id,
      'mode': card.mode.name,
      'selection': selection,
      'correct': selection == card.correctOption
    });
    feedback = true;
    clock.stop();
  }

  void reveal() {
    checkTime();
    if (!started || complete || feedback || card.mode != PracticeMode.recall)
      return;
    feedback = true;
    clock.stop();
  }

  void rate(bool recalled) {
    if (!feedback || complete || card.mode != PracticeMode.recall) return;
    if (recalled) {
      remembered++;
    } else {
      again++;
    }
    outcomes.add({
      'id': card.id,
      'mode': card.mode.name,
      'rating': recalled ? 'remembered' : 'again'
    });
    _advance();
  }

  void next() {
    if (!feedback || complete || card.mode == PracticeMode.recall) return;
    _advance();
  }

  void _advance() {
    if (index == cards.length - 1) {
      complete = true;
      clock.stop();
      return;
    }
    index++;
    selection = null;
    feedback = false;
    clock.start();
  }

  void dispose() => clock.stop();
}
