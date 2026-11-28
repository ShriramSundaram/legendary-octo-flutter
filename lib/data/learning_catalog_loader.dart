import 'package:flutter/services.dart';
import 'content_catalog.dart';

Future<ContentCatalog> loadLearningCatalog({bool includeDrafts = false}) async {
  final sources = await Future.wait([
    rootBundle.loadString('assets/content_catalog_v1.json'),
    rootBundle.loadString('assets/mission_vocabulary_v1.json'),
    rootBundle.loadString('assets/advanced_vocabulary_v1.json'),
  ]);
  return ContentCatalog.combine(sources.map(ContentCatalog.decode),
      includeDrafts: includeDrafts);
}
