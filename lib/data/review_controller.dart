import 'content_catalog.dart';
import 'learning_models.dart';
import 'review_scheduler.dart';
import 'review_store.dart';

class ReviewSession {
  final List<String> ids;
  final String level;
  final String? topic;
  final int position, again, remembered;
  ReviewSession(
      {required List<String> ids,
      required this.level,
      this.topic,
      this.position = 0,
      this.again = 0,
      this.remembered = 0})
      : ids = List.unmodifiable(ids) {
    if (!contentLevels.contains(level) ||
        ids.length > 10 ||
        ids.toSet().length != ids.length ||
        position < 0 ||
        position > ids.length ||
        again < 0 ||
        remembered < 0 ||
        again + remembered != position) {
      throw const FormatException('Invalid saved review session');
    }
  }
  bool get complete => position == ids.length;
  Map<String, dynamic> toMap() => {
        'ids': ids,
        'level': level,
        'topic': topic,
        'position': position,
        'again': again,
        'remembered': remembered
      };
  factory ReviewSession.fromMap(Map<String, dynamic> data) => ReviewSession(
      ids: List<String>.from(data['ids'] as List),
      level: data['level'] as String,
      topic: data['topic'] as String?,
      position: data['position'] as int,
      again: data['again'] as int,
      remembered: data['remembered'] as int);
}

class ReviewController {
  final ReviewStorage storage;
  final ReviewScheduler scheduler;
  final Map<String, CatalogWord> words;
  Map<String, LearningState> _states = {};
  ReviewSession? session;
  bool _saving = false;
  ReviewController(ContentCatalog catalog, this.storage,
      {DateTime Function()? clock})
      : scheduler = ReviewScheduler(clock: clock),
        words = {
          for (final w in catalog.words)
            if (w.item.editorialStatus == 'published') w.item.id: w
        } {
    final saved = storage.read();
    if (saved == null) return;
    if (saved['schemaVersion'] != 1 || saved['states'] is! Map) {
      throw const FormatException('Unsupported saved review data');
    }
    for (final entry in (saved['states'] as Map).entries) {
      final state =
          decodeReviewState(Map<String, dynamic>.from(entry.value as Map));
      if (state.itemId != entry.key)
        throw const FormatException('Review state ID mismatch');
      _states[state.itemId] = state;
    }
    if (saved['session'] != null)
      session = ReviewSession.fromMap(
          Map<String, dynamic>.from(saved['session'] as Map));
  }
  Map<String, LearningState> get states => Map.unmodifiable(_states);
  bool get canResume =>
      session != null &&
      !session!.complete &&
      session!.ids.every(words.containsKey);
  CatalogWord? get current => session == null || session!.complete
      ? null
      : words[session!.ids[session!.position]];
  List<CatalogWord> eligible(String level, String? topic) => words.values
      .where((w) =>
          w.item.level == level && (topic == null || w.item.topic == topic))
      .toList();
  int dueCount(String level, String? topic) {
    final now = scheduler.clock().toUtc();
    return eligible(level, topic)
        .where((w) =>
            _states[w.item.id] != null &&
            !_states[w.item.id]!.dueAt.isAfter(now))
        .length;
  }

  int newCount(String level, String? topic) => eligible(level, topic)
      .where((w) => !_states.containsKey(w.item.id))
      .length;

  Map<String, dynamic> _snapshot(
          Map<String, LearningState> states, ReviewSession? session) =>
      {
        'schemaVersion': 1,
        'states': {
          for (final entry in states.entries)
            entry.key: encodeReviewState(entry.value)
        },
        'session': session?.toMap(),
      };

  Future<bool> start(String level, String? topic,
      {bool includeNew = true}) async {
    if (_saving) return false;
    if (canResume) return true;
    final now = scheduler.clock().toUtc();
    final items = eligible(level, topic);
    final due = items
        .where((w) =>
            _states[w.item.id] != null &&
            !_states[w.item.id]!.dueAt.isAfter(now))
        .toList()
      ..sort((a, b) {
        final order =
            _states[a.item.id]!.dueAt.compareTo(_states[b.item.id]!.dueAt);
        return order == 0 ? a.item.id.compareTo(b.item.id) : order;
      });
    final fresh = items.where((w) => !_states.containsKey(w.item.id)).toList()
      ..sort((a, b) => a.item.id.compareTo(b.item.id));
    final ids = [
      ...due.map((w) => w.item.id),
      if (includeNew) ...fresh.take(10).map((w) => w.item.id)
    ].take(10).toList();
    if (ids.isEmpty) return false;
    final next = ReviewSession(ids: ids, level: level, topic: topic);
    _saving = true;
    try {
      await storage.write(_snapshot(_states, next));
      session = next;
      return true;
    } finally {
      _saving = false;
    }
  }

  /// Caller supplies the displayed cursor, rejecting double taps and stale cards.
  Future<bool> answer(RecallAnswer answer,
      {required int expectedPosition, required String expectedItemId}) async {
    final active = session;
    if (_saving ||
        active == null ||
        active.complete ||
        active.position != expectedPosition ||
        active.ids[active.position] != expectedItemId) return false;
    if (current == null) throw StateError('Saved word is unavailable');
    _saving = true;
    try {
      final nextStates = Map<String, LearningState>.from(_states);
      nextStates[expectedItemId] =
          scheduler.answer(expectedItemId, _states[expectedItemId], answer);
      final next = ReviewSession(
          ids: active.ids,
          level: active.level,
          topic: active.topic,
          position: active.position + 1,
          again: active.again + (answer == RecallAnswer.again ? 1 : 0),
          remembered:
              active.remembered + (answer == RecallAnswer.remembered ? 1 : 0));
      await storage.write(_snapshot(nextStates, next));
      _states = nextStates;
      session = next;
      return true;
    } finally {
      _saving = false;
    }
  }
}
