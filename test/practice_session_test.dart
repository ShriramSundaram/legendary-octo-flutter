import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:germanreminder/data/account_store.dart';
import 'package:germanreminder/data/practice_history.dart';
import 'package:germanreminder/data/practice_session.dart';
import 'package:germanreminder/data/practice_speech.dart';
import 'package:germanreminder/data/content_catalog.dart';
import 'package:germanreminder/data/quiz_catalog.dart';
import 'package:germanreminder/data/topic_test_builder.dart';
import 'package:germanreminder/data/test_report.dart';
import 'package:germanreminder/germanQuizData.dart';
import 'package:germanreminder/practice_page.dart';

const choice = PracticeCard(
    id: 'choice',
    prompt: 'house',
    answer: 'das Haus',
    explanation: 'Haus is neuter. Use das.',
    options: ['das Haus', 'der Hund'],
    correctOption: 0);
const recall = PracticeCard(
    id: 'recall',
    prompt: 'das Haus',
    answer: 'house',
    explanation: 'Das Haus ist klein. The house is small.',
    mode: PracticeMode.recall);
const listening = PracticeCard(
    id: 'listening',
    prompt: 'house',
    answer: 'das Haus',
    explanation: 'Haus is neuter. Use das.',
    options: ['das Haus', 'der Hund'],
    mode: PracticeMode.listening);

class FakeClock extends Stopwatch {
  Duration time = Duration.zero;
  bool running = false;
  @override
  Duration get elapsed => time;
  @override
  bool get isRunning => running;
  @override
  void start() {
    running = true;
  }

  @override
  void stop() {
    running = false;
  }

  void advance(Duration duration) {
    if (running) time += duration;
  }
}

class FakeSpeech implements PracticeSpeech {
  bool available = true, success = true;
  int plays = 0, stops = 0;
  @override
  Future<bool> prepare() async => available;
  @override
  Future<bool> speak(String text) async {
    plays++;
    return success;
  }

  @override
  Future<void> stop() async {
    stops++;
  }
}

class DelayedSpeech extends FakeSpeech {
  final ready = Completer<bool>();
  @override
  Future<bool> prepare() => ready.future;
}

void main() {
  test('submission is counted once and requires feedback before advancing', () {
    final s = PracticeSession([choice, choice])..start();
    s.next();
    expect(s.index, 0);
    s.select(1);
    s.submit();
    s.submit();
    s.select(0);
    expect(s.wrong, 1);
    expect(s.correct, 0);
    expect(s.feedback, true);
    expect(s.index, 0);
    s.next();
    s.next();
    expect(s.index, 1);
    expect(s.selection, null);
    s.select(0);
    s.submit();
    expect(s.complete, false); // Last explanation must also be read.
    s.next();
    s.next();
    expect(s.complete, true);
    expect([s.correct, s.wrong, s.unanswered], [1, 1, 0]);
  });
  test('selected but unsubmitted answer is unanswered at exact timeout', () {
    final clock = FakeClock();
    final s = PracticeSession([choice, choice],
        clock: clock, limit: const Duration(seconds: 2))
      ..start();
    s.select(0);
    clock.advance(const Duration(seconds: 2));
    s.submit();
    s.submit();
    expect(s.timedOut, true);
    expect([s.correct, s.wrong, s.unanswered], [0, 0, 2]);
    expect(clock.isRunning, false);
  });
  test('feedback pauses the monotonic timer and next question resumes it', () {
    final clock = FakeClock();
    final s = PracticeSession([choice, choice],
        clock: clock, limit: const Duration(seconds: 3))
      ..start();
    clock.advance(const Duration(seconds: 1));
    s.select(0);
    s.submit();
    clock.advance(const Duration(hours: 1));
    s.checkTime();
    expect(s.remaining, const Duration(seconds: 2));
    expect(s.complete, false);
    s.next();
    clock.advance(const Duration(seconds: 2));
    s.checkTime();
    expect(s.timedOut, true);
    expect(s.correct + s.wrong + s.unanswered, s.scoredTotal);
  });
  test('recall self-ratings never inflate scored accuracy', () {
    final s = PracticeSession([recall, recall, choice])..start();
    s.rate(true);
    expect(s.index, 0);
    s.reveal();
    s.rate(true);
    s.rate(true);
    s.reveal();
    s.rate(false);
    s.select(0);
    s.submit();
    s.next();
    expect([s.remembered, s.again, s.unrated], [1, 1, 0]);
    expect([s.correct, s.wrong, s.unanswered], [1, 0, 0]);
  });
  test('empty session cannot start and disposing stops the clock', () {
    final empty = PracticeSession([])..start();
    expect(empty.started, false);
    final clock = FakeClock();
    final s = PracticeSession([choice], clock: clock)..start();
    s.dispose();
    expect(clock.isRunning, false);
  });
  test(
      'topic tests contain recognition/listening only and preserve curated questions',
      () {
    final content = ContentCatalog.decode(
        File('assets/content_catalog_v1.json').readAsStringSync());
    final quizzes = QuizCatalog.decode(
        File('assets/quiz_catalog_v1.json').readAsStringSync(), content);
    for (final level in contentLevels) {
      final cards = buildTopicTest(content, quizzes, level);
      expect(cards.any((c) => c.mode == PracticeMode.recall), false);
      expect(cards.length, lessThanOrEqualTo(10));
      expect(cards.map((c) => c.id).toSet().length, cards.length);
      for (final card in cards.where((c) => c.mode != PracticeMode.recall)) {
        final original = quizzes
            .visible(level: level)
            .firstWhere((q) => '${q.itemId}:${card.mode.name}' == card.id);
        expect(card.options, original.options);
        expect(card.explanation, original.explanation);
      }
    }
    expect(buildTopicTest(content, quizzes, 'C2'), isEmpty);
    final topic = content.published('A1').first.item.topic;
    final allowed =
        content.published('A1', topic: topic).map((w) => w.item.id).toSet();
    expect(
        buildTopicTest(content, quizzes, 'A1', topic: topic)
            .every((c) => allowed.contains(c.id.split(':').first)),
        true);
    expect(buildTopicTest(content, quizzes, 'A1', topic: 'missing'), isEmpty);
  });
  test('history is idempotent, bounded and account isolated', () async {
    final directory = await Directory.systemTemp.createTemp('m04-history-');
    Hive.init(directory.path);
    final box = await Hive.openBox('m04-history');
    try {
      AccountStore.activeUid = 'A';
      final a = AccountStore(box, 'A');
      final history = PracticeHistory(a);
      for (var i = 0; i < 52; i++) {
        await history.save({'id': '$i', 'correct': i});
      }
      await history.save({'id': '51', 'correct': 51});
      final rows = a.get('practiceSessionsV1') as List;
      expect(rows.length, 50);
      expect(rows.first['id'], '2');
      AccountStore.activeUid = 'B';
      expect(AccountStore(box, 'B').get('practiceSessionsV1'), null);
      await expectLater(
          history.save({'id': 'wrong-account'}), throwsStateError);
      AccountStore.activeUid = 'A';
      expect((a.get('practiceSessionsV1') as List).length, 50);
    } finally {
      AccountStore.activeUid = null;
      await box.close();
      await directory.delete(recursive: true);
    }
  });

  Future<void> open(WidgetTester tester, List<PracticeCard> cards,
      {FakeSpeech? speech,
      Future<void> Function(Map<String, dynamic>)? save,
      Duration? limit}) async {
    await tester.pumpWidget(MaterialApp(
        home: PracticePage(
            cards: cards,
            level: 'A1',
            speech: speech ?? FakeSpeech(),
            saveResult: save ?? (_) async {},
            limit: limit)));
    await tester.tap(find.text('Start'));
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'wrong answer shows correction and explanation before result; replay resets',
      (tester) async {
    var saves = 0;
    await open(tester, [choice], save: (_) async {
      saves++;
    });
    await tap(tester, 'der Hund');
    await tap(tester, 'Check answer');
    expect(find.text('Correct response: das Haus'), findsOneWidget);
    expect(find.text(choice.explanation), findsOneWidget);
    expect(find.text('Test complete'), findsNothing);
    await tap(tester, 'Finish');
    expect(find.text('What was tested'), findsOneWidget);
    expect(find.text('Review next'), findsOneWidget);
    expect(
        find.textContaining(
            'This test does not establish or certify a CEFR level.'),
        findsOneWidget);
    expect(find.text('das Haus — house'), findsOneWidget);
    expect(saves, 1);
    expect(find.text('Wrong: 1'), findsOneWidget);
    await tap(tester, 'Retake test');
    await tap(tester, 'Start');
    await tap(tester, 'das Haus');
    await tap(tester, 'Check answer');
    await tap(tester, 'Finish');
    expect(find.text('Correct: 1'), findsOneWidget);
    expect(find.text('Wrong: 0'), findsOneWidget);
    expect(saves, 2);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('listening permits replay and explicit text alternative',
      (tester) async {
    final speech = FakeSpeech();
    await open(tester, [listening], speech: speech);
    expect(find.text('house'), findsNothing);
    await tap(tester, 'Play / replay German');
    await tap(tester, 'Play / replay German');
    expect(speech.plays, 2);
    await tap(tester, 'Use text question');
    expect(find.text('house'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(speech.stops, greaterThan(0));
  });

  test('quick check samples three distinct questions per A1-B2 level', () {
    final content = ContentCatalog.decode(
        File('assets/content_catalog_v1.json').readAsStringSync());
    final quizzes = QuizCatalog.decode(
        File('assets/quiz_catalog_v1.json').readAsStringSync(), content);
    final cards = buildQuickVocabularyCheck(
        quizzes.visible().map(GermanQuiz.fromItem).toList());
    expect(cards.length, 12);
    expect(cards.map((c) => c.id).toSet().length, 12);
    for (final level in ['A1', 'A2', 'B1', 'B2']) {
      expect(cards.where((c) => c.level == level).length, 3);
    }
    expect(cards.every((c) => c.mode == PracticeMode.recognition), true);
    expect(buildQuickVocabularyCheck([]), isEmpty);
    final session = PracticeSession(cards)..start();
    // Miss an A1 sample; the recommendation remains practice, not placement.
    session
        .select((session.card.correctOption + 1) % session.card.options.length);
    session.submit();
    session.next();
    while (!session.complete) {
      session.select(session.card.correctOption);
      session.submit();
      session.next();
    }
    final report = TestReport(session);
    expect(report.suggestedLevel, 'A1');
    expect(report.reviewNext.length, 1);
    expect(report.count(cards.where((c) => c.level == 'A1')), '2 / 3 correct');
  });

  testWidgets(
      'quick check result shows level sample and practice recommendation',
      (tester) async {
    final cards = [
      for (final level in ['A1', 'A2', 'B1', 'B2'])
        for (var i = 0; i < 3; i++)
          PracticeCard(
              id: '$level:$i',
              level: level,
              prompt: 'house $i',
              answer: 'das Haus',
              explanation: choice.explanation,
              options: choice.options)
    ];
    await tester.pumpWidget(MaterialApp(
        home: PracticePage(
            cards: cards,
            level: 'A1–B2',
            quickCheck: true,
            speech: FakeSpeech(),
            saveResult: (_) async {})));
    await tap(tester, 'Start');
    for (var i = 0; i < 12; i++) {
      await tap(tester, i == 0 ? 'der Hund' : 'das Haus');
      await tap(tester, 'Check answer');
      await tap(tester, i == 11 ? 'Finish' : 'Continue');
    }
    expect(find.text('A1: 2 / 3 correct'), findsOneWidget);
    expect(find.text('B2: 3 / 3 correct'), findsOneWidget);
    expect(find.textContaining('Suggested practice: A1.'), findsOneWidget);
    expect(find.textContaining('C1/C2 not assessed.'), findsOneWidget);
    expect(find.text('Reveal meaning'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('text fallback is reported separately from listening',
      (tester) async {
    await open(tester, [listening]);
    await tap(tester, 'Use text question');
    await tap(tester, 'das Haus');
    await tap(tester, 'Check answer');
    await tap(tester, 'Finish');
    expect(find.text('Text alternatives (not listening): 1 / 1 correct'),
        findsOneWidget);
    expect(find.text('Listening: 1 / 1 correct'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('missing voice and playback failure show usable text fallback',
      (tester) async {
    for (final available in [false, true]) {
      final speech = FakeSpeech()
        ..available = available
        ..success = false;
      await open(tester, [listening], speech: speech);
      await tap(tester, 'Play / replay German');
      expect(find.text('house'), findsOneWidget);
      await tap(tester, 'das Haus');
      await tap(tester, 'Check answer');
      expect(find.text(choice.explanation), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });
  testWidgets(
      'save failure retries same result without blocking the result screen',
      (tester) async {
    final ids = <String>[];
    await open(tester, [choice], save: (s) async {
      ids.add(s['id'] as String);
      if (ids.length == 1) throw StateError('fixture');
    });
    await tap(tester, 'das Haus');
    await tap(tester, 'Check answer');
    await tap(tester, 'Finish');
    expect(find.text('Test complete'), findsOneWidget);
    await tap(tester, 'Retry saving');
    expect(ids.length, 2);
    expect(ids[0], ids[1]);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'timeout leaves unsubmitted selection unanswered and disposing cancels ticker',
      (tester) async {
    await open(tester, [choice], limit: Duration.zero);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Time is up'), findsOneWidget);
    expect(find.text('Unanswered: 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), null);
  });
  testWidgets('test result supports narrow screens with large text',
      (tester) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: PracticePage(
            cards: const [choice],
            level: 'C2',
            speech: FakeSpeech(),
            saveResult: (_) async {})));
    await tap(tester, 'Start');
    await tap(tester, 'das Haus');
    await tap(tester, 'Check answer');
    await tap(tester, 'Finish');
    expect(find.text('Test complete'), findsOneWidget);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'back navigation cancels playback and ignores a late voice response',
      (tester) async {
    final speech = DelayedSpeech();
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PracticePage(
                                cards: const [listening],
                                level: 'A1',
                                speech: speech))),
                    child: const Text('Open'))))));
    await tap(tester, 'Open');
    await tap(tester, 'Start');
    await tester.tap(find.text('Play / replay German'));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    speech.ready.complete(true);
    await tester.pump();
    expect(speech.plays, 0);
    expect(speech.stops, greaterThan(0));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), null);
  });
}
