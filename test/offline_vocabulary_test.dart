import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/data/offline_vocabulary.dart';
import 'package:germanreminder/data/offline_vocabulary_loader.dart';

String content() => File('assets/content_catalog_v1.json').readAsStringSync();
String legacy() => File('assets/legacy_vocabulary_v1.json').readAsStringSync();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('offline deck retains structured words and every unique legacy source',
      () {
    final deck = OfflineVocabulary.decode(content(), legacy());
    expect(deck.words.length, 1328);
    expect(deck.words.map((w) => w.id).toSet().length, 1328);
    for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']) {
      expect(deck.atLevel(level), isNotEmpty);
    }
    final rows = jsonDecode(legacy())['items'] as List;
    expect(rows.length, 1059);
    expect(
        rows.fold<int>(
            0, (sum, row) => sum + (row['sourceIndexes'] as List).length),
        1060);
    for (final row in rows) {
      final word = deck.words.singleWhere((w) => w.id == row['id']);
      expect(word.original, row['original']);
      expect(word.german, row['german']);
      expect(word.meaning, row['meaning']);
    }
  });
  test('malformed or duplicate legacy entries cannot silently replace content',
      () {
    for (final change in [
      {'german': ''},
      {'meaning': null},
      {'level': 'D1'}
    ]) {
      final data = jsonDecode(legacy());
      (data['items'][0] as Map).addAll(change);
      expect(() => OfflineVocabulary.decode(content(), jsonEncode(data)),
          throwsFormatException);
    }
    final data = jsonDecode(legacy());
    data['items'].add(data['items'][0]);
    expect(() => OfflineVocabulary.decode(content(), jsonEncode(data)),
        throwsFormatException);
    expect(() => OfflineVocabulary.levelForCollection('Unknown'),
        throwsFormatException);
    expect(OfflineVocabulary.levelForCollection('GenericCollectionsC2'), 'C2');
  });
  test('unpublished structured words remain excluded from the shared deck', () {
    final data = jsonDecode(content());
    data['items'][0]['editorialStatus'] = 'draft';
    final deck = OfflineVocabulary.decode(jsonEncode(data), legacy());
    expect(deck.words.length, 1327);
    expect(deck.words.any((w) => w.id == data['items'][0]['id']), isFalse);
  });
  test('cold asset load needs no Firebase initialization or network client',
      () async {
    final deck = await loadOfflineVocabulary();
    expect(deck.words.length, 1608);
    expect(deck.atLevel('A1').length, 515);
  });
}
