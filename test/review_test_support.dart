import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:germanreminder/data/content_catalog.dart';
import 'package:germanreminder/data/review_store.dart';

final reviewNow = DateTime.parse('2026-11-25T23:59:00Z');
ContentCatalog reviewCatalog(
    {int count = 12, String level = 'A1', String topic = 'Test topic'}) {
  final data =
      jsonDecode(File('assets/content_catalog_v1.json').readAsStringSync());
  final first = Map<String, dynamic>.from(data['items'][0]);
  data['items'] = List.generate(
      count,
      (i) => {
            ...first,
            'id': 'word_${i.toString().padLeft(2, '0')}',
            'lemma': 'Wort$i',
            'meaning': 'meaning-$i',
            'article': '',
            'plural': '',
            'partOfSpeech': 'phrase',
            'level': level,
            'topic': topic,
            'example': 'Beispiel $i.',
            'exampleTranslation': 'Example $i.'
          });
  return ContentCatalog.decode(jsonEncode(data));
}

class MemoryReviewStorage implements ReviewStorage {
  Map<String, dynamic>? value;
  bool fail = false;
  int writes = 0;
  Completer<void>? gate;
  @override
  Map<String, dynamic>? read() =>
      value == null ? null : jsonDecode(jsonEncode(value));
  @override
  Future<void> write(Map<String, dynamic> data) async {
    if (gate != null) await gate!.future;
    if (fail) throw StateError('Simulated write failure');
    value = jsonDecode(jsonEncode(data));
    writes++;
  }
}
