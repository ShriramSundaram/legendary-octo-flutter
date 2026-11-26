import 'package:flutter/services.dart';
import 'offline_vocabulary.dart';

Future<OfflineVocabulary>? _cached;

Future<OfflineVocabulary> loadOfflineVocabulary() async {
  try {
    return await (_cached ??= _load());
  } catch (_) {
    _cached = null;
    rethrow;
  }
}

Future<OfflineVocabulary> _load() async {
  final sources = await Future.wait([
    rootBundle.loadString('assets/content_catalog_v1.json'),
    rootBundle.loadString('assets/legacy_vocabulary_v1.json'),
  ]);
  return OfflineVocabulary.decode(sources[0], sources[1]);
}
