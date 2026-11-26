import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'learning_models.dart';

abstract class MigrationStore {
  Future<void> ensureWord(PersonalWord word);
  Future<PersonalWord?> readWord(String id);
  Future<void> checkpoint(Map<String, dynamic> report);
}

class MigrationReport {
  final String sourceDigest;
  final int uniqueWords, copiedWords, invalidEntries;
  final bool reconciled;
  const MigrationReport(this.sourceDigest, this.uniqueWords, this.copiedWords,
      this.invalidEntries, this.reconciled);
  Map<String, dynamic> toMap() => {
        'schemaVersion': 1,
        'sourceDigest': sourceDigest,
        'uniqueWords': uniqueWords,
        'copiedWords': copiedWords,
        'invalidEntries': invalidEntries,
        'reconciled': reconciled,
      };
}

/// Replaying the source is intentional: legacy clients may have added words
/// since a checkpoint. Each individual copy is create-if-absent and idempotent.
Future<MigrationReport> migrateLegacy(
    Object? source, MigrationStore store) async {
  final words = <String, PersonalWord>{};
  var invalid = 0;
  if (source != null && source is! List) invalid++;
  for (final value in source is List ? source : const []) {
    try {
      if (value is! String) throw const FormatException();
      final word = PersonalWord.fromText(value);
      words[word.id] = word;
    } on FormatException {
      invalid++;
    }
  }
  final identities = words.keys.toList()..sort();
  final digest =
      sha256.convert(utf8.encode(jsonEncode([identities, invalid]))).toString();
  var copied = 0;
  await store.checkpoint(
      MigrationReport(digest, words.length, 0, invalid, false).toMap());
  for (final word in words.values) {
    await store.ensureWord(word);
    copied++;
    if (copied % 25 == 0) {
      await store.checkpoint(
          MigrationReport(digest, words.length, copied, invalid, false)
              .toMap());
    }
  }
  for (final word in words.values) {
    final actual = await store.readWord(word.id);
    if (actual?.lemma != word.lemma)
      throw StateError('Migration reconciliation failed.');
  }
  final report =
      MigrationReport(digest, words.length, copied, invalid, invalid == 0);
  await store.checkpoint(report.toMap());
  return report;
}
