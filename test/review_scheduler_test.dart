import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:germanreminder/data/account_store.dart';
import 'package:germanreminder/data/review_store.dart';
import 'package:germanreminder/data/review_scheduler.dart';
import 'package:germanreminder/data/review_controller.dart';
import 'review_test_support.dart';

void main() {
  test('first recall and lapse use separate bounded intervals', () {
    final scheduler = ReviewScheduler(clock: () => reviewNow);
    final success = scheduler.answer('word', null, RecallAnswer.remembered);
    final lapse = scheduler.answer('word', null, RecallAnswer.again);
    expect(success.intervalSeconds, 86400);
    expect(success.lapseCount, 0);
    expect(lapse.intervalSeconds, 600);
    expect(lapse.lapseCount, 1);
    expect(success.dueAt, reviewNow.add(const Duration(days: 1)));
    expect(decodeReviewState(encodeReviewState(success)).dueAt, success.dueAt);
  });
  test(
      'success intervals increase and cap; repeated lapses reset without escalation',
      () {
    final scheduler = ReviewScheduler(clock: () => reviewNow);
    var state = scheduler.answer('word', null, RecallAnswer.remembered);
    for (final step in ReviewScheduler.steps.skip(1)) {
      state = scheduler.answer('word', state, RecallAnswer.remembered);
      expect(state.intervalSeconds, step);
    }
    expect(
        scheduler
            .answer('word', state, RecallAnswer.remembered)
            .intervalSeconds,
        ReviewScheduler.steps.last);
    state = scheduler.answer('word', state, RecallAnswer.again);
    state = scheduler.answer('word', state, RecallAnswer.again);
    expect(state.intervalSeconds, 600);
    expect(state.lapseCount, 2);
    expect(
        scheduler
            .answer('word', state, RecallAnswer.remembered)
            .intervalSeconds,
        86400);
  });
  test('midnight and timezone offsets use elapsed UTC durations', () {
    final now = DateTime.parse('2026-11-26T05:29:00+05:30');
    final result = ReviewScheduler(clock: () => now)
        .answer('word', null, RecallAnswer.again);
    expect(result.lastAttempt, reviewNow);
    expect(result.dueAt, DateTime.parse('2026-11-26T00:09:00Z'));
    expect(result.dueAt.isUtc, isTrue);
  });
  test('backwards clock never moves a previous attempt or next due backwards',
      () {
    final first = ReviewScheduler(clock: () => reviewNow)
        .answer('word', null, RecallAnswer.remembered);
    final backwards = ReviewScheduler(
            clock: () => reviewNow.subtract(const Duration(days: 3)))
        .answer('word', first, RecallAnswer.remembered);
    expect(backwards.lastAttempt, first.lastAttempt);
    expect(backwards.dueAt, reviewNow.add(const Duration(days: 3)));
    final data = encodeReviewState(first)..['schedulerVersion'] = 999;
    expect(() => decodeReviewState(data), throwsFormatException);
  });
  test('empty decks and due-only sessions do not create fake progress',
      () async {
    final storage = MemoryReviewStorage();
    final controller = ReviewController(reviewCatalog(count: 0), storage,
        clock: () => reviewNow);
    expect(await controller.start('A1', null), isFalse);
    expect(storage.writes, 0);
    final fresh =
        ReviewController(reviewCatalog(), storage, clock: () => reviewNow);
    expect(await fresh.start('A1', null, includeNew: false), isFalse);
    expect(fresh.states, isEmpty);
  });
  test('due words precede new words and future words are excluded', () async {
    final storage = MemoryReviewStorage();
    final scheduler = ReviewScheduler(
        clock: () => reviewNow.subtract(const Duration(days: 2)));
    final due = scheduler.answer('word_11', null, RecallAnswer.remembered);
    final future = ReviewScheduler(clock: () => reviewNow)
        .answer('word_00', null, RecallAnswer.remembered);
    storage.value = {
      'schemaVersion': 1,
      'states': {
        'word_11': encodeReviewState(due),
        'word_00': encodeReviewState(future)
      },
      'session': null
    };
    final controller =
        ReviewController(reviewCatalog(), storage, clock: () => reviewNow);
    expect(controller.dueCount('A1', null), 1);
    expect(await controller.start('A1', null), isTrue);
    expect(controller.session!.ids.length, 10);
    expect(controller.session!.ids.first, 'word_11');
    expect(controller.session!.ids, isNot(contains('word_00')));
  });
  test('all levels and topics use same scheduler without leaking selection',
      () async {
    for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']) {
      final c = ReviewController(
          reviewCatalog(level: level), MemoryReviewStorage(),
          clock: () => reviewNow);
      expect(await c.start(level, 'Other topic'), isFalse);
      expect(await c.start(level, 'Test topic'), isTrue);
      expect(c.current!.item.level, level);
    }
  });
  test('a saved Again word becomes due at exactly ten minutes after reopening',
      () async {
    var now = reviewNow;
    final storage = MemoryReviewStorage();
    var controller =
        ReviewController(reviewCatalog(count: 1), storage, clock: () => now);
    await controller.start('A1', null);
    final id = controller.current!.item.id;
    await controller.answer(RecallAnswer.again,
        expectedPosition: 0, expectedItemId: id);
    now = reviewNow.add(const Duration(minutes: 9, seconds: 59));
    controller =
        ReviewController(reviewCatalog(count: 1), storage, clock: () => now);
    expect(controller.dueCount('A1', null), 0);
    expect(await controller.start('A1', null, includeNew: false), isFalse);
    now = reviewNow.add(const Duration(minutes: 10));
    expect(controller.dueCount('A1', null), 1);
    expect(await controller.start('A1', null, includeNew: false), isTrue);
    expect(controller.session!.ids, [id]);
    await controller.answer(RecallAnswer.remembered,
        expectedPosition: 0, expectedItemId: id);
    now = now.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    controller =
        ReviewController(reviewCatalog(count: 1), storage, clock: () => now);
    expect(controller.dueCount('A1', null), 0);
    now = now.add(const Duration(seconds: 1));
    expect(controller.dueCount('A1', null), 1);
  });
  test(
      'answer checkpoint resumes cursor and rejects stale duplicate submission',
      () async {
    final storage = MemoryReviewStorage();
    var c = ReviewController(reviewCatalog(), storage, clock: () => reviewNow);
    await c.start('A1', null);
    final first = c.current!.item.id;
    expect(
        await c.answer(RecallAnswer.remembered,
            expectedPosition: 0, expectedItemId: first),
        isTrue);
    final writes = storage.writes;
    c = ReviewController(reviewCatalog(), storage, clock: () => reviewNow);
    expect(c.session!.position, 1);
    expect(c.states.length, 1);
    expect(
        await c.answer(RecallAnswer.again,
            expectedPosition: 0, expectedItemId: first),
        isFalse);
    expect(storage.writes, writes);
    expect(c.session!.remembered, 1);
    expect(await c.start('B2', null), isTrue);
    expect(c.session!.level, 'A1');
    while (!c.session!.complete) {
      await c.answer(RecallAnswer.again,
          expectedPosition: c.session!.position,
          expectedItemId: c.current!.item.id);
    }
    final resumed =
        ReviewController(reviewCatalog(), storage, clock: () => reviewNow);
    expect(resumed.session!.complete, isTrue);
    expect(resumed.states.length, 10);
    expect(resumed.session!.again + resumed.session!.remembered, 10);
  });
  test('double taps while saving commit only one answer', () async {
    final storage = MemoryReviewStorage();
    final c =
        ReviewController(reviewCatalog(), storage, clock: () => reviewNow);
    await c.start('A1', null);
    storage.gate = Completer<void>();
    final id = c.current!.item.id;
    final first =
        c.answer(RecallAnswer.again, expectedPosition: 0, expectedItemId: id);
    expect(
        await c.answer(RecallAnswer.remembered,
            expectedPosition: 0, expectedItemId: id),
        isFalse);
    storage.gate!.complete();
    expect(await first, isTrue);
    expect(c.states[id]!.lapseCount, 1);
    expect(c.session!.position, 1);
    expect(storage.writes, 2);
  });
  test('write failure leaves current card and schedule intact for retry',
      () async {
    final storage = MemoryReviewStorage();
    final c =
        ReviewController(reviewCatalog(), storage, clock: () => reviewNow);
    await c.start('A1', null);
    final id = c.current!.item.id;
    storage.fail = true;
    await expectLater(
        c.answer(RecallAnswer.again, expectedPosition: 0, expectedItemId: id),
        throwsStateError);
    expect(c.session!.position, 0);
    expect(c.states, isEmpty);
    storage.fail = false;
    expect(
        await c.answer(RecallAnswer.again,
            expectedPosition: 0, expectedItemId: id),
        isTrue);
    expect(c.session!.position, 1);
  });
  test('removed content restarts safely while retaining completed states',
      () async {
    final storage = MemoryReviewStorage();
    final c =
        ReviewController(reviewCatalog(), storage, clock: () => reviewNow);
    await c.start('A1', null);
    await c.answer(RecallAnswer.remembered,
        expectedPosition: 0, expectedItemId: c.current!.item.id);
    final changed = ReviewController(reviewCatalog(count: 2), storage,
        clock: () => reviewNow);
    expect(changed.canResume, isFalse);
    expect(await changed.start('A1', null), isTrue);
    expect(changed.states.length, 1);
    expect(changed.session!.ids, ['word_01']);
  });
  test('corrupt or future-format snapshots are retained and never reset', () {
    final storage = MemoryReviewStorage()
      ..value = {'schemaVersion': 2, 'states': {}};
    expect(() => ReviewController(reviewCatalog(), storage),
        throwsFormatException);
    expect(storage.value!['schemaVersion'], 2);
    expect(storage.writes, 0);
  });
  test('real Hive checkpoints survive reopening and stay isolated by account',
      () async {
    final directory = await Directory.systemTemp.createTemp('m03-review-');
    Hive.init(directory.path);
    var box = await Hive.openBox('review');
    try {
      AccountStore.activeUid = 'A';
      final storeA = AccountReviewStorage(AccountStore(box, 'A'));
      final c =
          ReviewController(reviewCatalog(), storeA, clock: () => reviewNow);
      await c.start('A1', null);
      await c.answer(RecallAnswer.again,
          expectedPosition: 0, expectedItemId: c.current!.item.id);
      AccountStore.activeUid = 'B';
      expect(AccountReviewStorage(AccountStore(box, 'B')).read(), isNull);
      final b = ReviewController(reviewCatalog(), AccountReviewStorage(AccountStore(box, 'B')));
      expect(b.progress.goal, 10);
      expect(b.progress.days, isEmpty);
      await b.setDailyGoal(5);
      expect(() => storeA.read(), throwsStateError);
      await expectLater(storeA.write({'schemaVersion': 1}), throwsStateError);
      await box.close();
      box = await Hive.openBox('review');
      AccountStore.activeUid = 'A';
      final resumed = ReviewController(
          reviewCatalog(), AccountReviewStorage(AccountStore(box, 'A')),
          clock: () => reviewNow);
      expect(resumed.session!.position, 1);
      expect(resumed.states.length, 1);
      expect(resumed.progress.goal, 10);
      expect(resumed.progress.on(reviewNow.toLocal()).reviews, 1);
    } finally {
      AccountStore.activeUid = null;
      await box.close();
      await directory.delete(recursive: true);
    }
  });
}
