import 'package:flutter/services.dart';
import 'offline_vocabulary.dart';

final _cached = <bool, Future<OfflineVocabulary>>{};

Future<OfflineVocabulary> loadOfflineVocabulary(
    {bool includeDrafts = false}) async {
  try {
    return await (_cached[includeDrafts] ??= _load(includeDrafts));
  } catch (_) {
    _cached.remove(includeDrafts);
    rethrow;
  }
}

Future<OfflineVocabulary> _load(bool includeDrafts) async {
  final sources = await Future.wait([
    rootBundle.loadString('assets/content_catalog_v1.json'),
    rootBundle.loadString('assets/legacy_vocabulary_v1.json'),
    rootBundle.loadString('assets/mission_vocabulary_v1.json'),
    rootBundle.loadString('assets/advanced_vocabulary_v1.json'),
  ]);
  return OfflineVocabulary.decode(sources[0], sources[1],
      supplementalSource: sources[2],
      additionalSources: [sources[3]],
      includeDrafts: includeDrafts);
}
