import 'dart:io';
import '../lib/data/content_catalog.dart';
import '../lib/data/quiz_catalog.dart';
import '../lib/data/offline_vocabulary.dart';

void main(List<String> args) {
  try {
    final path = args.where((arg) => !arg.startsWith('--')).firstOrNull ??
        'assets/content_catalog_v1.json';
    final catalog = ContentCatalog.decode(File(path).readAsStringSync());
    final quizzes = QuizCatalog.decode(
        File('assets/quiz_catalog_v1.json').readAsStringSync(), catalog);
    if (args.contains('--publish-ready') &&
        (catalog.words.isEmpty ||
            catalog.words.any((w) => w.item.editorialStatus != 'published') ||
            quizzes.items.isEmpty ||
            quizzes.items.any((q) => q.editorialStatus != 'published'))) {
      throw const FormatException(
          'Catalog contains drafts or has no published words');
    }
    stdout.writeln(
        'Valid catalog v${catalog.version}: ${catalog.words.length} items');
    for (final level in contentLevels) {
      stdout.writeln('$level: ${catalog.published(level).length} published');
    }
    stdout.writeln(
        'Valid quiz catalog: ${quizzes.items.length} questions; ${quizzes.visible().length} published');
    final offline = OfflineVocabulary.decode(File(path).readAsStringSync(),
        File('assets/legacy_vocabulary_v1.json').readAsStringSync());
    stdout.writeln(
        'Offline vocabulary: ${offline.words.length} traceable entries');
  } catch (error) {
    stderr.writeln('Content validation failed: $error');
    exitCode = 1;
  }
}
