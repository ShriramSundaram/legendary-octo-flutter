import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/content_library_page.dart';
import 'package:germanreminder/learning_progress_panel.dart';
import 'package:germanreminder/data/review_controller.dart';
import 'package:germanreminder/data/review_scheduler.dart';
import 'review_test_support.dart';

void main() {
  final now = DateTime(2026, 11, 27, 12);
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  testWidgets('review completion refreshes home credit and goal can be edited',
      (tester) async {
    final storage = MemoryReviewStorage();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: LearningProgressPanel(
                    storage: storage,
                    loadCatalog: () async => reviewCatalog(count: 1),
                    clock: () => now)))));
    await tester.pumpAndSettle();
    expect(find.text('0 / 10 reviews today'), findsOneWidget);
    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start practice'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Reveal meaning'));
    await tester.tap(find.text('Reveal meaning'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Remembered'));
    await tester.tap(find.text('Remembered'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 10 reviews today'), findsOneWidget);
    await tester.tap(find.text('Edit goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 reviews'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 5 reviews today'), findsOneWidget);
    expect(storage.value!['progressV1']['goal'], 5);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'goal, week and distinct quiz/recall labels fit 320px at 200 percent',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = MemoryReviewStorage();
    final c =
        ReviewController(reviewCatalog(count: 1), storage, clock: () => now);
    await c.start('A1', null);
    await c.answer(RecallAnswer.again,
        expectedPosition: 0, expectedItemId: c.current!.item.id);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: Scaffold(
            body: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LearningProgressPanel(
                        storage: storage,
                        loadCatalog: () async => reviewCatalog(count: 1),
                        clock: () => now,
                        loadHistory: () => [
                              {
                                'id': 'quiz',
                                'completedAt': now.toUtc().toIso8601String(),
                                'correct': 2,
                                'wrong': 1
                              }
                            ]))))));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Your last 7 days'));
    await tester.tap(find.text('Your last 7 days'));
    await tester.pumpAndSettle();
    await reveal(tester, find.textContaining('Quiz accuracy: 67%'));
    expect(find.text('Today’s recall: 0 Remembered · 1 Again'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'library search, reveal and pinned actions do not award review credit',
      (tester) async {
    final storage = MemoryReviewStorage();
    await tester.pumpWidget(MaterialApp(
        home: ContentLibraryPage(
            reviewStorage: storage,
            loadCatalog: () async => reviewCatalog(count: 3))));
    await tester.pumpAndSettle();
    expect(find.text('Start practice').hitTestable(), findsOneWidget);
    expect(find.text('Start Test').hitTestable(), findsOneWidget);
    await reveal(tester, find.text('Wort0'));
    await tester.tap(find.text('Wort0'));
    await tester.pumpAndSettle();
    expect(find.text('meaning-0'), findsOneWidget);
    expect(find.text('Hear pronunciation'), findsOneWidget);
    expect(storage.writes, 0);
    await reveal(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'meaning-1');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    expect(find.text('1 word shown'), findsOneWidget);
    await reveal(tester, find.text('Wort1'));
    expect(find.text('Wort0'), findsNothing);
    expect(storage.writes, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'library recovers from a loading error without resetting progress',
      (tester) async {
    var attempts = 0;
    final storage = MemoryReviewStorage();
    await tester.pumpWidget(MaterialApp(
        home: ContentLibraryPage(
            reviewStorage: storage,
            loadCatalog: () async {
              if (attempts++ == 0) throw StateError('offline load failure');
              return reviewCatalog(count: 1);
            })));
    await tester.pumpAndSettle();
    expect(find.text('Could not load the learning library.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('A1 (1 words)'), findsOneWidget);
    expect(storage.writes, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
