import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/content_library_page.dart';
import 'package:germanreminder/data/content_catalog.dart';

Map<String, dynamic> fixture() =>
    jsonDecode(File('assets/content_catalog_v1.json').readAsStringSync())
        as Map<String, dynamic>;

Future<ContentCatalog> loadFixtureCatalog() async =>
    ContentCatalog.decode(jsonEncode(fixture()));

Future<ContentCatalog> loadDraftCatalog() async {
  final data = fixture();
  for (final row in data['items']) {
    row['editorialStatus'] = 'draft';
  }
  return ContentCatalog.decode(jsonEncode(data));
}

String levelLabel(String level) {
  final rows = fixture()['items'] as List;
  return '$level (${rows.where((row) => row['level'] == level).length} words)';
}

void main() {
  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  Future<void> returnToHeader(WidgetTester tester) async {
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
  }

  test('owner-approved starter content is published at all six levels', () {
    final catalog = ContentCatalog.decode(jsonEncode(fixture()));
    expect(catalog.words.length, greaterThanOrEqualTo(225));
    final a1 = catalog.browse('A1', includeDrafts: true);
    expect(a1.length, greaterThanOrEqualTo(150));
    final topics = a1.map((w) => w.item.topic).toSet();
    expect(topics.length, 10);
    for (final topic in topics) {
      expect(catalog.browse('A1', includeDrafts: true, topic: topic).length,
          greaterThanOrEqualTo(15));
    }
    for (final level in contentLevels.skip(1)) {
      expect(catalog.browse(level, includeDrafts: true).length,
          greaterThanOrEqualTo(15));
    }
    for (final level in contentLevels) {
      expect(catalog.published(level).length,
          catalog.browse(level, includeDrafts: true).length);
    }
  });

  test('same publication and topic filters work at every level', () {
    final data = fixture();
    final original = Map<String, dynamic>.from((data['items'] as List).first);
    data['items'] = contentLevels
        .map((level) => {
              ...original,
              'id': 'item_$level',
              'level': level,
              'editorialStatus': 'published',
              'reviewer': 'Test fixture only',
              'reviewedAt': '2026-11-25T00:00:00Z',
            })
        .toList();
    final catalog = ContentCatalog.decode(jsonEncode(data));
    for (final level in contentLevels) {
      expect(catalog.published(level).single.item.level, level);
      expect(catalog.published(level, topic: 'Greetings').length, 1);
      expect(catalog.published(level, topic: 'Home'), isEmpty);
    }
  });

  test('rejects duplicate IDs and duplicate level/lemma pairs', () {
    final data = fixture();
    final items = data['items'] as List;
    items.add({...Map<String, dynamic>.from(items.first)});
    expect(
        () => ContentCatalog.decode(jsonEncode(data)), throwsFormatException);
    (items.last as Map)['id'] = 'different_id';
    expect(
        () => ContentCatalog.decode(jsonEncode(data)), throwsFormatException);
  });

  test('rejects unsigned publication, missing translation and incomplete nouns',
      () {
    for (final change in <Map<String, dynamic>>[
      {'editorialStatus': 'published', 'reviewer': ''},
      {'exampleTranslation': ''},
      {'partOfSpeech': 'noun', 'article': '', 'plural': ''},
    ]) {
      final data = fixture();
      (data['items'] as List)[0].addAll(change);
      expect(
          () => ContentCatalog.decode(jsonEncode(data)), throwsFormatException);
    }
  });

  testWidgets('library explains unavailable content and allows level selection',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: ContentLibraryPage(
            previewDrafts: false, loadCatalog: loadDraftCatalog)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reviewed A1 content is being prepared'),
        findsOneWidget);
    expect(find.text('Hallo, ich heiße Anna.'), findsNothing);
    await reveal(tester, find.text('B2 (0 words)'));
    await tester.tap(find.text('B2 (0 words)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reviewed B2 content is being prepared'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'published offline library shows counts, examples and level/topic filters',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: ContentLibraryPage(loadCatalog: loadFixtureCatalog)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vocabulary preview'), findsNothing);
    expect(find.text(levelLabel('A1')), findsOneWidget);
    await tester.tap(find.text(levelLabel('A2')));
    await tester.pumpAndSettle();
    expect(find.text('25 words shown'), findsOneWidget);
    await reveal(tester, find.text('umziehen'));
    await tester.tap(find.text('umziehen'));
    await tester.pumpAndSettle();
    expect(find.text('We are moving home next month.'), findsOneWidget);
    await returnToHeader(tester);
    await reveal(tester, find.text('Travel'));
    await tester.tap(find.text('Travel'));
    await tester.pumpAndSettle();
    expect(find.text('5 words shown'), findsOneWidget);
    await returnToHeader(tester);
    await reveal(tester, find.text(levelLabel('B2')));
    await tester.tap(find.text(levelLabel('B2')));
    await tester.pumpAndSettle();
    expect(find.text('26 words shown'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('level and topic choices fit a narrow screen with large text',
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
        home: const ContentLibraryPage(loadCatalog: loadFixtureCatalog)));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('C2 (15 words)'));
    await tester.tap(find.text('C2 (15 words)'));
    await tester.pumpAndSettle();
    expect(find.text('15 words shown'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
