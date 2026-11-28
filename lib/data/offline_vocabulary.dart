import 'dart:convert';
import 'content_catalog.dart';

/// Shared vocabulary is packaged with the app. Personal words remain separate.
class OfflineWord {
  final String id, level, german, meaning, original;
  final bool preview;
  const OfflineWord(
      this.id, this.level, this.german, this.meaning, this.original,
      {this.preview = false});
  String get display => '$german - $meaning';
}

class OfflineVocabulary {
  final List<OfflineWord> words;
  OfflineVocabulary._(this.words);
  factory OfflineVocabulary.decode(String contentSource, String legacySource,
      {String? supplementalSource,
      Iterable<String> additionalSources = const [],
      bool includeDrafts = false}) {
    final catalog = ContentCatalog.combine([
      ContentCatalog.decode(contentSource),
      if (supplementalSource != null) ContentCatalog.decode(supplementalSource),
      ...additionalSources.map(ContentCatalog.decode),
    ], includeDrafts: includeDrafts);
    final legacy = jsonDecode(legacySource) as Map<String, dynamic>;
    if (legacy['schemaVersion'] != 1 ||
        legacy['version'] is! int ||
        legacy['version'] < 1 ||
        legacy['items'] is! List ||
        legacy['reviewer'] is! String ||
        (legacy['reviewer'] as String).trim().isEmpty ||
        legacy['rights'] is! String ||
        (legacy['rights'] as String).trim().isEmpty ||
        DateTime.tryParse(legacy['reviewedAt'] as String? ?? '') == null) {
      throw const FormatException('Invalid offline legacy vocabulary');
    }
    final words = <OfflineWord>[
      for (final word in catalog.words)
        if (word.item.editorialStatus == 'published' ||
            (includeDrafts && word.item.editorialStatus == 'draft'))
          OfflineWord(
              word.item.id,
              word.item.level,
              '${word.item.article} ${word.item.lemma}'.trim(),
              word.item.meaning,
              '',
              preview: word.item.editorialStatus != 'published'),
    ];
    final ids = words.map((w) => w.id).toSet();
    for (final raw in legacy['items'] as List) {
      final row = Map<String, dynamic>.from(raw);
      for (final key in ['id', 'level', 'german', 'meaning', 'original']) {
        if (row[key] is! String || (row[key] as String).trim().isEmpty) {
          throw FormatException('Invalid legacy $key');
        }
      }
      if (!contentLevels.contains(row['level']) ||
          row['id'].contains('/') ||
          !ids.add(row['id']))
        throw const FormatException('Duplicate or invalid legacy item');
      words.add(OfflineWord(row['id'], row['level'], row['german'],
          row['meaning'], row['original']));
    }
    return OfflineVocabulary._(List.unmodifiable(words));
  }

  List<OfflineWord> atLevel(String level) =>
      words.where((word) => word.level == level).toList(growable: false);

  static String levelForCollection(String collection) => switch (collection) {
        'GenericCollections' => 'A1',
        'GenericCollectionsA2' => 'A2',
        'GenericCollectionsB1' => 'B1',
        'GenericCollectionsB2' => 'B2',
        'GenericCollectionsC1' => 'C1',
        'GenericCollectionsC2' => 'C2',
        _ => throw const FormatException('Unknown vocabulary collection'),
      };
}
