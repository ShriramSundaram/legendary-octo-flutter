import 'dart:convert';
import 'content_catalog.dart';

String _quizText(Map<String, dynamic> data, String key, int max) {
  final value = data[key];
  if (value is! String || value.trim().isEmpty || value.length > max) {
    throw FormatException('Invalid quiz $key');
  }
  return value;
}

class QuizItem {
  final String id, itemId, level, question, explanation, editorialStatus;
  final String source, rights, legacyAuditReference;
  final List<String> options;
  final int correctOption;
  final bool contentQuarantined;

  QuizItem.fromMap(Map<String, dynamic> data, Map<String, CatalogWord> content)
      : id = _quizText(data, 'id', 128),
        itemId = _quizText(data, 'itemId', 128),
        level = _quizText(data, 'level', 10),
        question = _quizText(data, 'question', 1000),
        explanation = _quizText(data, 'explanation', 4000),
        editorialStatus = _quizText(data, 'editorialStatus', 20),
        source = _quizText(data, 'source', 2000),
        rights = _quizText(data, 'rights', 2000),
        legacyAuditReference = data['legacyAuditReference'] as String? ?? '',
        correctOption =
            data['correctOption'] is int ? data['correctOption'] as int : -1,
        options = data['options'] is List &&
                (data['options'] as List).every((v) => v is String)
            ? List<String>.unmodifiable(data['options'] as List)
            : const [],
        contentQuarantined =
            content[data['itemId']]?.item.editorialStatus == 'quarantined' {
    final word = content[itemId];
    if (data['schemaVersion'] != 1 ||
        data['direction'] != 'enToDe' ||
        data['version'] is! int ||
        (data['version'] as int) < 1 ||
        !contentLevels.contains(level) ||
        id.contains('/') ||
        word == null ||
        word.item.level != level ||
        !['draft', 'reviewed', 'published', 'quarantined']
            .contains(editorialStatus) ||
        options.length != 4 ||
        options.any((v) => v.trim().isEmpty || v.length > 300) ||
        options.map((v) => v.trim().toLowerCase()).toSet().length != 4 ||
        correctOption < 0 ||
        correctOption >= options.length) {
      throw FormatException('Invalid quiz structure or content reference: $id');
    }
    final correct = '${word.item.article} ${word.item.lemma}'.trim();
    if (options[correctOption] != correct) {
      throw FormatException(
          'Quiz answer does not match referenced content: $id');
    }
    if (['reviewed', 'published'].contains(editorialStatus)) {
      final reviewer = data['reviewer'];
      final date = data['reviewedAt'];
      if (reviewer is! String ||
          reviewer.trim().isEmpty ||
          date is! String ||
          DateTime.tryParse(date) == null ||
          !['reviewed', 'published'].contains(word.item.editorialStatus) ||
          (editorialStatus == 'published' &&
              word.item.editorialStatus != 'published')) {
        throw FormatException(
            'Quiz and content editorial signoff required: $id');
      }
    }
  }
}

class QuizCatalog {
  final int version;
  final List<QuizItem> items;
  QuizCatalog._(this.version, this.items);
  factory QuizCatalog.decode(String source, ContentCatalog content) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    if (data['schemaVersion'] != 1 ||
        data['version'] is! int ||
        (data['version'] as int) < 1 ||
        data['items'] is! List) {
      throw const FormatException('Unsupported quiz catalog');
    }
    final words = {for (final word in content.words) word.item.id: word};
    final items = (data['items'] as List)
        .map((row) => QuizItem.fromMap(Map<String, dynamic>.from(row), words))
        .toList();
    final ids = <String>{};
    for (final item in items) {
      if (!ids.add(item.id))
        throw FormatException('Duplicate quiz ID: ${item.id}');
    }
    return QuizCatalog._(data['version'] as int, List.unmodifiable(items));
  }
  List<QuizItem> visible({bool includeDrafts = false, String? level}) => items
      .where((item) =>
          !item.contentQuarantined &&
          (level == null || item.level == level) &&
          (item.editorialStatus == 'published' ||
              (includeDrafts && item.editorialStatus == 'draft')))
      .toList(growable: false);
}
