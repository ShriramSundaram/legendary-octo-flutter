import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/data/content_catalog.dart';
import 'package:germanreminder/review_session_page.dart';
import 'review_test_support.dart';

void main() {
  testWidgets('recall hides meaning until reveal, then saves honest summary',
      (tester) async {
    final storage = MemoryReviewStorage();
    await tester.pumpWidget(MaterialApp(
        home: ReviewSessionPage(
            storage: storage,
            clock: () => reviewNow,
            loadCatalog: () async => reviewCatalog(count: 1))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start practice'));
    await tester.pumpAndSettle();
    expect(find.text('meaning-0'), findsNothing);
    expect(find.text('Remembered'), findsNothing);
    await tester.tap(find.text('Reveal meaning'));
    await tester.pumpAndSettle();
    expect(find.text('meaning-0'), findsOneWidget);
    expect(find.text('Example 0.'), findsOneWidget);
    await tester.tap(find.text('Remembered'));
    await tester.pumpAndSettle();
    expect(find.text('Session complete'), findsOneWidget);
    expect(find.text('1 Remembered · 0 Again'), findsOneWidget);
    expect(find.textContaining('Self-reported recall'), findsOneWidget);
    expect(storage.writes, 2);
  });
  testWidgets('leaving and reopening resumes at next hidden card',
      (tester) async {
    final storage = MemoryReviewStorage();
    Widget page() => MaterialApp(
        home: ReviewSessionPage(
            storage: storage,
            clock: () => reviewNow,
            loadCatalog: () async => reviewCatalog(count: 2)));
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reveal meaning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue saved session'));
    await tester.pumpAndSettle();
    expect(find.text('Word 2 of 2'), findsOneWidget);
    expect(find.text('meaning-1'), findsNothing);
  });
  testWidgets('failed save can retry without skipping the card',
      (tester) async {
    final storage = MemoryReviewStorage();
    await tester.pumpWidget(MaterialApp(
        home: ReviewSessionPage(
            storage: storage,
            loadCatalog: () async => reviewCatalog(count: 2))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reveal meaning'));
    await tester.pumpAndSettle();
    storage.fail = true;
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Your answer was not confirmed'), findsOneWidget);
    expect(find.text('Word 1 of 2'), findsOneWidget);
    storage.fail = false;
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();
    expect(find.text('Word 2 of 2'), findsOneWidget);
  });
  testWidgets('narrow screen and double text remain usable without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: ReviewSessionPage(
            storage: MemoryReviewStorage(),
            loadCatalog: () async => reviewCatalog(count: 1))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start practice'));
    await tester.tap(find.text('Start practice'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reveal meaning'));
    await tester.tap(find.text('Reveal meaning'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Remembered'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('leaving during loading never updates disposed screen',
      (tester) async {
    final pending = Completer<ContentCatalog>();
    await tester.pumpWidget(MaterialApp(
        home: ReviewSessionPage(
            storage: MemoryReviewStorage(),
            loadCatalog: () => pending.future)));
    await tester.pumpWidget(const SizedBox());
    pending.complete(reviewCatalog());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
