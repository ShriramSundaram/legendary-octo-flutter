import 'dart:convert';
import 'package:crypto/crypto.dart';

String personalWordId(String word) => 'p_${sha256.convert(utf8.encode(word))}';

/// Exact legacy text determines identity: case and whitespace are preserved.
class PersonalWord {
  final String id;
  final String lemma;
  const PersonalWord(this.id, this.lemma);
  factory PersonalWord.fromText(String text) {
    if (text.isEmpty || text.length > 10000) {
      throw const FormatException('Word length must be between 1 and 10000.');
    }
    return PersonalWord(personalWordId(text), text);
  }
  factory PersonalWord.fromMap(Map<String, dynamic> data) {
    if (data['schemaVersion'] != 1 || data['lemma'] is! String) {
      throw const FormatException('Unsupported personal word.');
    }
    final word = PersonalWord.fromText(data['lemma'] as String);
    if (word.id != data['id']) throw const FormatException('Word ID mismatch.');
    return word;
  }
  Map<String, dynamic> toMap() =>
      {'schemaVersion': 1, 'id': id, 'lemma': lemma};
}

class ContentItem {
  final String id, lemma, article, plural, meaning, example, topic, level;
  final String source, rights, editorialStatus;
  final int version;
  ContentItem.fromMap(Map<String, dynamic> data)
      : id = _text(data, 'id', 128),
        lemma = _text(data, 'lemma', 300),
        article = _text(data, 'article', 10, empty: true),
        plural = _text(data, 'plural', 300, empty: true),
        meaning = _text(data, 'meaning', 1000),
        example = _text(data, 'example', 2000),
        topic = _text(data, 'topic', 100),
        level = _text(data, 'level', 10),
        source = _text(data, 'source', 2000),
        rights = _text(data, 'rights', 2000),
        editorialStatus = _text(data, 'editorialStatus', 20),
        version = _integer(data, 'version', 1, 1000000) {
    if (data['schemaVersion'] != 1 ||
        !['draft', 'reviewed', 'published', 'quarantined']
            .contains(editorialStatus) ||
        !['A1', 'A2', 'B1', 'B2', 'C1', 'C2'].contains(level)) {
      throw const FormatException('Unsupported content schema.');
    }
  }
  Map<String, dynamic> toMap() => {
        'schemaVersion': 1,
        'id': id,
        'lemma': lemma,
        'article': article,
        'plural': plural,
        'meaning': meaning,
        'example': example,
        'topic': topic,
        'level': level,
        'source': source,
        'rights': rights,
        'editorialStatus': editorialStatus,
        'version': version,
      };
}

class LearningState {
  final String itemId;
  final DateTime dueAt;
  final DateTime? lastAttempt;
  final int intervalSeconds, lapseCount, schedulerVersion;
  LearningState(
      {required this.itemId,
      required DateTime dueAt,
      DateTime? lastAttempt,
      required this.intervalSeconds,
      required this.lapseCount,
      required this.schedulerVersion})
      : dueAt = dueAt.toUtc(),
        lastAttempt = lastAttempt?.toUtc() {
    if (itemId.isEmpty ||
        itemId.length > 128 ||
        itemId.contains('/') ||
        intervalSeconds < 0 ||
        intervalSeconds > 315360000 ||
        lapseCount < 0 ||
        lapseCount > 1000000 ||
        schedulerVersion < 1 ||
        schedulerVersion > 1000000) {
      throw const FormatException('Invalid learning state.');
    }
  }
}

String _text(Map<String, dynamic> data, String key, int max,
    {bool empty = false}) {
  final value = data[key];
  if (value is! String || (!empty && value.isEmpty) || value.length > max) {
    throw FormatException('Invalid $key');
  }
  return value;
}

int _integer(Map<String, dynamic> data, String key, int min, int max) {
  final value = data[key];
  if (value is! int || value < min || value > max)
    throw FormatException('Invalid $key');
  return value;
}
