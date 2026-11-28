import 'dart:convert';
import 'learning_models.dart';

const contentLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

String _required(Map<String, dynamic> value, String key) {
  final text = value[key];
  if (text is! String || text.trim().isEmpty) {
    throw FormatException('Missing $key');
  }
  return text;
}

/// Bundled editorial metadata extends the M01 model without changing Firestore.
class CatalogWord {
  final ContentItem item;
  final String exampleTranslation, partOfSpeech, usageNotes;
  final String reviewer, reviewedAt;
  CatalogWord.fromMap(Map<String, dynamic> data)
      : item = ContentItem.fromMap(data),
        exampleTranslation = _required(data, 'exampleTranslation'),
        partOfSpeech = _required(data, 'partOfSpeech'),
        usageNotes = data['usageNotes'] as String? ?? '',
        reviewer = data['reviewer'] as String? ?? '',
        reviewedAt = data['reviewedAt'] as String? ?? '' {
    if (!['noun', 'verb', 'adjective', 'adverb', 'phrase', 'other']
        .contains(partOfSpeech)) {
      throw const FormatException('Invalid part of speech');
    }
    if (item.id.contains('/') || item.id.trim() != item.id) {
      throw const FormatException('Invalid item ID');
    }
    if (partOfSpeech == 'noun' &&
        (!['der', 'die', 'das'].contains(item.article) ||
            item.plural.trim().isEmpty)) {
      throw const FormatException('Nouns require article and plural');
    }
    if (['reviewed', 'published'].contains(item.editorialStatus) &&
        (reviewer.trim().isEmpty || DateTime.tryParse(reviewedAt) == null)) {
      throw const FormatException('Editorial signoff required');
    }
  }
}

class ContentCatalog {
  final int version;
  final List<CatalogWord> words;
  ContentCatalog._(this.version, this.words);

  factory ContentCatalog.combine(Iterable<ContentCatalog> catalogs,
      {bool includeDrafts = false}) {
    final words = <CatalogWord>[], ids = <String>{}, lemmas = <String>{};
    var version = 1;
    for (final catalog in catalogs) {
      if (catalog.version > version) version = catalog.version;
      for (final word in catalog.words) {
        if (word.item.editorialStatus != 'published' &&
            !(includeDrafts && word.item.editorialStatus == 'draft')) continue;
        if (!ids.add(word.item.id) ||
            !lemmas.add(
                '${word.item.level}:${word.item.lemma.toLowerCase().trim()}')) {
          throw const FormatException('Duplicate content across packs');
        }
        words.add(word);
      }
    }
    return ContentCatalog._(version, List.unmodifiable(words));
  }

  factory ContentCatalog.decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    if (data['schemaVersion'] != 1 ||
        data['version'] is! int ||
        (data['version'] as int) < 1 ||
        data['items'] is! List) {
      throw const FormatException('Unsupported catalog');
    }
    final words = (data['items'] as List)
        .map((row) => CatalogWord.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    final ids = <String>{};
    final entries = <String>{};
    for (final word in words) {
      if (!ids.add(word.item.id) ||
          !entries.add(
              '${word.item.level}:${word.item.lemma.trim().toLowerCase()}')) {
        throw FormatException('Duplicate content: ${word.item.id}');
      }
    }
    return ContentCatalog._(data['version'] as int, List.unmodifiable(words));
  }

  List<CatalogWord> published(String level, {String? topic}) => words
      .where((word) =>
          word.item.editorialStatus == 'published' &&
          word.item.level == level &&
          (topic == null || word.item.topic == topic))
      .toList(growable: false);

  /// Explicit authoring preview; production callers keep the published filter.
  List<CatalogWord> browse(String level,
          {String? topic, bool includeDrafts = false}) =>
      words
          .where((word) =>
              word.item.level == level &&
              (topic == null || word.item.topic == topic) &&
              (word.item.editorialStatus == 'published' ||
                  (includeDrafts && word.item.editorialStatus == 'draft')))
          .toList(growable: false);
}
