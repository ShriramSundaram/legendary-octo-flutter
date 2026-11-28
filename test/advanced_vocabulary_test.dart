import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/data/content_catalog.dart';
import 'package:germanreminder/data/learning_catalog_loader.dart';
import 'package:germanreminder/data/offline_vocabulary_loader.dart';
import 'package:germanreminder/data/review_controller.dart';
import 'package:germanreminder/data/review_scheduler.dart';
import 'review_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pack = ContentCatalog.decode(
      File('assets/advanced_vocabulary_v1.json').readAsStringSync());
  test('advanced pack has forty complete original entries per requested level',
      () {
    expect(pack.words.length, 160);
    expect(pack.words.where((w) => w.partOfSpeech == 'noun').length, 80);
    expect(pack.words.where((w) => w.partOfSpeech == 'verb').length, 48);
    expect(pack.words.where((w) => w.partOfSpeech == 'adjective').length, 32);
    for (final level in ['B1', 'B2', 'C1', 'C2']) {
      final words = pack.words.where((w) => w.item.level == level);
      expect(words.length, 40);
      for (final word in words) {
        expect(word.item.example.trim(), isNotEmpty);
        expect(word.exampleTranslation.trim(), isNotEmpty);
        expect(word.item.meaning.trim(), isNotEmpty);
        expect(word.item.source, contains('Original'));
        expect(word.item.editorialStatus, 'published');
        expect(word.reviewer, isNotEmpty);
        expect(DateTime.tryParse(word.reviewedAt), isNotNull);
        if (word.partOfSpeech == 'noun') {
          expect(['der', 'die', 'das'], contains(word.item.article));
          expect(word.item.plural, isNotEmpty);
        }
      }
    }
  });
  test('owner-approved new entries are included in the production catalog',
      () async {
    final preview = await loadLearningCatalog(includeDrafts: true);
    final published = await loadLearningCatalog();
    expect(preview.words.length, 549);
    expect(published.words.length, 549);
    final ids = pack.words.map((w) => w.item.id).toSet();
    expect(preview.words.where((w) => ids.contains(w.item.id)).length, 160);
    expect(published.words.where((w) => ids.contains(w.item.id)).length, 160);
    expect(preview.words.map((w) => w.item.id).toSet().length,
        preview.words.length);
  });
  test('cold offline preview includes every new word without Firebase',
      () async {
    final offline = await loadOfflineVocabulary(includeDrafts: true);
    expect(offline.words.length, 1608);
    for (final entry in {'B1': 390, 'B2': 303, 'C1': 152, 'C2': 75}.entries) {
      expect(offline.atLevel(entry.key).length, entry.value);
    }
    final ids = offline.words.map((w) => w.id).toSet();
    expect(pack.words.every((w) => ids.contains(w.item.id)), true);
    final public = await loadOfflineVocabulary();
    expect(public.words.length, 1608);
  });
  test(
      'new vocabulary uses existing recall checkpoint and resumes by stable ID',
      () async {
    final catalog = await loadLearningCatalog(includeDrafts: true);
    final storage = MemoryReviewStorage();
    final ids = pack.words
        .where((w) => w.item.level == 'B2')
        .take(4)
        .map((w) => w.item.id)
        .toSet();
    final controller = ReviewController(catalog, storage,
        onlyItemIds: ids, previewDrafts: true, clock: () => reviewNow);
    await controller.start('B2', null);
    expect(controller.session!.ids.toSet(), ids);
    final first = controller.current!.item.id;
    await controller.answer(RecallAnswer.remembered,
        expectedPosition: 0, expectedItemId: first);
    final restored = ReviewController(catalog, storage,
        previewDrafts: true, clock: () => reviewNow);
    expect(restored.canResume, true);
    expect(restored.session!.position, 1);
    expect(restored.states[first]!.intervalSeconds, 86400);
  });
}
