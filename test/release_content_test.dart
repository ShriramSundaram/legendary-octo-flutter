import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/data/content_catalog.dart';
import 'package:germanreminder/data/learning_catalog_loader.dart';
import 'package:germanreminder/data/missions.dart';
import 'package:germanreminder/data/offline_vocabulary_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('release content matches the explicit owner inclusion snapshot',
      () async {
    final approval = jsonDecode(
        File('docs/m11-release-content-approval.json').readAsStringSync());
    expect(approval['ownerDecision'], 'Include the new content');
    for (final entry in (approval['catalogs'] as Map).entries) {
      expect(
          sha256
              .convert(File(entry.key as String).readAsBytesSync())
              .toString(),
          entry.value['sha256']);
    }
    final missions = decodeMissions(
        File('assets/missions_catalog_v1.json').readAsStringSync());
    final catalog = await loadLearningCatalog();
    expect(missions.length, 30);
    expect(catalog.words.length, 549);
    expect((await loadOfflineVocabulary()).words.length, 1608);
    final ids = catalog.words.map((w) => w.item.id).toSet();
    for (final m in missions) {
      expect(m.steps.length, 10);
      expect(m.steps.every((s) => s.choices.length == 3), true);
      expect(m.usefulWords.every(ids.contains), true);
    }
  });
  test('future unapproved edits remain excluded from production vocabulary',
      () {
    final data = jsonDecode(
        File('assets/advanced_vocabulary_v1.json').readAsStringSync());
    final row = data['items'][0];
    row['editorialStatus'] = 'draft';
    row['reviewer'] = '';
    row['reviewedAt'] = '';
    final catalog = ContentCatalog.decode(jsonEncode(data));
    expect(ContentCatalog.combine([catalog]).words.length, 159);
    expect(
        ContentCatalog.combine([catalog])
            .words
            .any((w) => w.item.id == row['id']),
        false);
  });
}
