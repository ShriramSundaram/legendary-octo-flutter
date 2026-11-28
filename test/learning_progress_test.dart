import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/data/learning_progress.dart';
import 'package:germanreminder/data/review_controller.dart';
import 'package:germanreminder/data/review_scheduler.dart';
import 'review_test_support.dart';

void main() {
  test('an old session upgrades without inventing past daily activity',
      () async {
    final storage = MemoryReviewStorage();
    final old = ReviewController(reviewCatalog(count: 2), storage);
    await old.start('A1', null);
    storage.value!.remove('progressV1');
    (storage.value!['session'] as Map).remove('id');
    final c = ReviewController(reviewCatalog(count: 2), storage);
    expect(c.progress.goal, 10);
    expect(c.progress.days, isEmpty);
    expect(
        await c.answer(RecallAnswer.remembered,
            expectedPosition: 0, expectedItemId: c.current!.item.id),
        isTrue);
    expect(c.progress.on(DateTime.now()).reviews, 1);
    expect(storage.value!['session']['id'], isNotEmpty);
  });

  test('answer credit, state and resume cursor commit together; retry is safe',
      () async {
    final store = MemoryReviewStorage();
    final now = DateTime(2026, 11, 27, 12);
    final c =
        ReviewController(reviewCatalog(count: 1), store, clock: () => now);
    await c.start('A1', null);
    final id = c.current!.item.id;
    store.fail = true;
    await expectLater(
        c.answer(RecallAnswer.remembered,
            expectedPosition: 0, expectedItemId: id),
        throwsStateError);
    expect(c.progress.on(now).reviews, 0);
    expect(c.session!.position, 0);
    store.fail = false;
    expect(
        await c.answer(RecallAnswer.remembered,
            expectedPosition: 0, expectedItemId: id),
        isTrue);
    final reopened =
        ReviewController(reviewCatalog(count: 1), store, clock: () => now);
    expect(reopened.progress.on(now).reviews, 1);
    expect(reopened.progress.on(now).sessions, 1);
    expect(
        await reopened.answer(RecallAnswer.remembered,
            expectedPosition: 0, expectedItemId: id),
        isFalse);
    expect(reopened.progress.on(now).reviews, 1);
  });

  test('two screens cannot double-credit a stale card during a delayed write',
      () async {
    final store = MemoryReviewStorage();
    final c1 = ReviewController(reviewCatalog(count: 2), store);
    await c1.start('A1', null);
    final c2 = ReviewController(reviewCatalog(count: 2), store);
    final id = c1.current!.item.id;
    store.gate = Completer<void>();
    final first = c1.answer(RecallAnswer.remembered,
        expectedPosition: 0, expectedItemId: id);
    final second =
        c2.answer(RecallAnswer.again, expectedPosition: 0, expectedItemId: id);
    await Future<void>.delayed(Duration.zero);
    store.gate!.complete();
    expect(await first, isTrue);
    expect(await second, isFalse);
    expect(c2.progress.on(DateTime.now()).reviews, 1);
  });

  test('a goal edit waits for an answer and preserves its state and credit',
      () async {
    final store = MemoryReviewStorage();
    final review = ReviewController(reviewCatalog(count: 2), store);
    await review.start('A1', null);
    final settings = ReviewController(reviewCatalog(count: 2), store);
    store.gate = Completer<void>();
    final answer = review.answer(RecallAnswer.again,
        expectedPosition: 0, expectedItemId: review.current!.item.id);
    final goal = settings.setDailyGoal(5);
    await Future<void>.delayed(Duration.zero);
    store.gate!.complete();
    await answer;
    await goal;
    final reopened = ReviewController(reviewCatalog(count: 2), store);
    expect(reopened.progress.goal, 5);
    expect(reopened.progress.on(DateTime.now()).again, 1);
    expect(reopened.session!.position, 1);
    expect(reopened.states.length, 1);
  });

  test('midnight splits real answers; travel and replay never reassign credit',
      () async {
    var now = DateTime(2026, 11, 27, 23, 59);
    final store = MemoryReviewStorage();
    final c =
        ReviewController(reviewCatalog(count: 2), store, clock: () => now);
    await c.start('A1', null);
    await c.answer(RecallAnswer.again,
        expectedPosition: 0, expectedItemId: c.current!.item.id);
    now = DateTime(2026, 11, 28, 0, 1);
    await c.answer(RecallAnswer.remembered,
        expectedPosition: 1, expectedItemId: c.current!.item.id);
    expect(c.progress.on(now).reviews, 1);
    expect(c.progress.on(DateTime(2026, 11, 27)).reviews, 1);
    final same = c.progress.record(
        id: c.progress.credited.first,
        local: DateTime(2026, 11, 26),
        remembered: false,
        sessionComplete: false);
    expect(same.on(DateTime(2026, 11, 26)).reviews, 0);
    expect(same.on(DateTime(2026, 11, 27)).reviews, 1);
  });

  test('corrupt progress is rejected without writing over the saved state', () {
    final store = MemoryReviewStorage()
      ..value = {
        'schemaVersion': 1,
        'states': {},
        'session': null,
        'progressV1': {'schemaVersion': 99}
      };
    expect(
        () => ReviewController(reviewCatalog(), store), throwsFormatException);
    expect(store.writes, 0);
  });

  test('quiz accuracy ignores recall ratings, duplicate and future results',
      () {
    final now = DateTime(2026, 11, 27, 12);
    final valid = {
      'id': 'one',
      'completedAt':
          now.subtract(const Duration(hours: 1)).toUtc().toIso8601String(),
      'correct': 3,
      'wrong': 1,
      'remembered': 100,
      'again': 100,
      'unanswered': 2
    };
    final result = QuizAccuracy.recent([
      valid,
      valid,
      {
        ...valid,
        'id': 'future',
        'completedAt':
            now.add(const Duration(days: 1)).toUtc().toIso8601String()
      },
      {
        ...valid,
        'id': 'old',
        'completedAt':
            now.subtract(const Duration(days: 8)).toUtc().toIso8601String()
      }
    ], now);
    expect(result.correct, 3);
    expect(result.answered, 4);
  });
}
