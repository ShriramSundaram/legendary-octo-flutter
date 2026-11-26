import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/data/content_catalog.dart';
import 'package:germanreminder/data/quiz_catalog.dart';
import 'package:germanreminder/germanBasicTest.dart';
import 'package:germanreminder/germanQuizData.dart';

Map<String, dynamic> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
Map<String, dynamic> quizSource() => readJson('assets/quiz_catalog_v1.json');
ContentCatalog content() => ContentCatalog.decode(
    File('assets/content_catalog_v1.json').readAsStringSync());
QuizCatalog parse(Map<String, dynamic> data) =>
    QuizCatalog.decode(jsonEncode(data), content());

void main() {
  test(
      '55 owner-approved questions have stable references and preserved originals',
      () {
    final catalog = parse(quizSource());
    expect(catalog.items.length, 55);
    expect(catalog.items.map((q) => q.legacyAuditReference).toSet().length, 55);
    expect(catalog.visible().length, 55);
    expect(catalog.visible(includeDrafts: true).length, 55);
    expect(catalog.items.every((q) => q.explanation.isNotEmpty), isTrue);
    final audit = readJson('docs/m02-quiz-audit.json');
    final original =
        jsonDecode(File('assets/quiz_data.json').readAsStringSync()) as List;
    for (var i = 0; i < 55; i++) {
      expect(audit['items'][i]['question'], original[i]['question']);
      expect(audit['items'][i]['options'], original[i]['options']);
      expect(audit['items'][i]['reviewer'], isNull);
    }
  });
  test('corrections preserve umlauts and distinguish common mistranslations',
      () {
    final items = parse(quizSource()).items;
    expect(items[0].options[items[0].correctOption], 'sich hinlegen');
    expect(items[4].options[items[4].correctOption], 'preisgünstig');
    expect(items[9].options[items[9].correctOption], 'krabbeln');
    expect(items[12].options[items[12].correctOption], 'langweilig');
    expect(items[22].options[items[22].correctOption], 'besorgt');
    expect(items[42].question, contains('viable'));
    expect(items[42].explanation, contains('nachhaltig'));
  });
  test(
      'rejects duplicate IDs, invalid answers, broken references and missing explanations',
      () {
    for (final changes in <Map<String, dynamic>>[
      {'correctOption': -1},
      {'correctOption': 4},
      {'correctOption': 1.5},
      {
        'options': ['a', 'a', 'b', 'c']
      },
      {
        'options': ['a', 'b', 3, 'd']
      },
      {'itemId': 'missing'},
      {'level': 'C2'},
      {'explanation': ''},
      {'source': ''},
      {
        'options': ['a', 'b', 'c', 'd']
      },
      {'schemaVersion': 2},
    ]) {
      final data = quizSource();
      (data['items'][0] as Map).addAll(changes);
      expect(() => parse(data), throwsFormatException);
    }
    final data = quizSource();
    (data['items'] as List).add(Map<String, dynamic>.from(data['items'][0]));
    expect(() => parse(data), throwsFormatException);
  });
  test('published questions need both quiz and referenced word signoff', () {
    final quizzes = quizSource();
    final first = quizzes['items'][0] as Map<String, dynamic>;
    first.addAll({
      'editorialStatus': 'published',
      'reviewer': '',
      'reviewedAt': '2026-11-25T00:00:00Z'
    });
    expect(() => parse(quizzes), throwsFormatException);
    first['reviewer'] = 'Fixture only';
    final words = readJson('assets/content_catalog_v1.json');
    final word = (words['items'] as List)
            .firstWhere((word) => word['id'] == first['itemId'])
        as Map<String, dynamic>;
    word.addAll({
      'editorialStatus': 'published',
      'reviewer': 'Fixture only',
      'reviewedAt': '2026-11-25T00:00:00Z'
    });
    final catalog = QuizCatalog.decode(
        jsonEncode(quizzes), ContentCatalog.decode(jsonEncode(words)));
    expect(catalog.visible().length, 55);
  });
  test('quarantined content is excluded even from draft quiz preview', () {
    final quizzes = quizSource();
    quizzes['items'][0]['editorialStatus'] = 'draft';
    final words = readJson('assets/content_catalog_v1.json');
    ((words['items'] as List)
            .firstWhere((word) => word['id'] == quizzes['items'][0]['itemId'])
        as Map)['editorialStatus'] = 'quarantined';
    final catalog = QuizCatalog.decode(
        jsonEncode(quizzes), ContentCatalog.decode(jsonEncode(words)));
    expect(catalog.visible(includeDrafts: true).length, 54);
  });
  testWidgets(
      'empty approved content has a safe state instead of indexing an empty list',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: germanBasicTest(loadQuestions: () async => [])));
    await tester.pumpAndSettle();
    expect(
        find.text('Reviewed quiz content is being prepared.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed quiz loading can retry and safely show an empty result',
      (tester) async {
    var attempt = 0;
    await tester
        .pumpWidget(MaterialApp(home: germanBasicTest(loadQuestions: () async {
      if (attempt++ == 0) throw const FormatException('fixture');
      return [];
    })));
    await tester.pumpAndSettle();
    expect(find.text('Quiz content could not be loaded.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
        find.text('Reviewed quiz content is being prepared.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('leaving during quiz load does not update a disposed screen',
      (tester) async {
    final pending = Completer<List<GermanQuiz>>();
    await tester.pumpWidget(MaterialApp(
        home: germanBasicTest(loadQuestions: () => pending.future)));
    await tester.pumpWidget(const SizedBox());
    pending.complete([]);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
