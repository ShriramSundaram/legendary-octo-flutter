import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/data/learning_models.dart';
import 'package:germanreminder/data/legacy_migration.dart';
import 'package:germanreminder/data/account_store.dart';
import 'package:hive/hive.dart';

class MemoryMigrationStore implements MigrationStore {
  final words = <String, PersonalWord>{};
  final reports = <Map<String, dynamic>>[];
  int? failAfter;
  bool corruptRead = false;
  @override
  Future<void> ensureWord(PersonalWord word) async {
    if (failAfter == words.length) throw StateError('Simulated interruption');
    words.putIfAbsent(word.id, () => word);
  }

  @override
  Future<PersonalWord?> readWord(String id) async =>
      corruptRead ? null : words[id];
  @override
  Future<void> checkpoint(Map<String, dynamic> report) async {
    reports.add(report);
  }
}

void main() {
  test(
      'migration preserves exact unique words and can replay after interruption',
      () async {
    final source = ['Haus', 'haus', ' Haus ', 'Straße', 'Haus'];
    final store = MemoryMigrationStore()..failAfter = 2;
    await expectLater(migrateLegacy(source, store), throwsStateError);
    expect(store.reports.last['reconciled'], false);
    store.failAfter = null;
    final report = await migrateLegacy(source, store);
    expect(report.reconciled, true);
    expect(store.words.values.map((w) => w.lemma).toSet(), source.toSet());
    final repeat = await migrateLegacy(source, store);
    expect(repeat.sourceDigest, report.sourceDigest);
    expect(store.words.length, 4);
    await migrateLegacy([...source, 'neu'], store);
    expect(store.words.length, 5);
    expect(source.length, 5);
  });
  test('malformed entries are reported without losing valid words', () async {
    final store = MemoryMigrationStore();
    final report = await migrateLegacy([
      'Haus',
      3,
      null,
      '',
      'x' * 10001,
      {'bad': DateTime.now()}
    ], store);
    expect(report.invalidEntries, 5);
    expect(report.reconciled, false);
    expect(store.words.values.single.lemma, 'Haus');
    expect(
        (await migrateLegacy(null, MemoryMigrationStore())).reconciled, true);
    expect(
        (await migrateLegacy('bad', MemoryMigrationStore())).reconciled, false);
  });
  test('failed reconciliation never marks migration complete', () async {
    final store = MemoryMigrationStore()..corruptRead = true;
    await expectLater(migrateLegacy(['Haus'], store), throwsStateError);
    expect(store.reports.last['reconciled'], false);
  });
  test('stable IDs survive serialization and reject corrupted identity', () {
    final word = PersonalWord.fromText('Straße');
    expect(PersonalWord.fromMap(word.toMap()).id, word.id);
    expect(word.id, isNot(personalWordId('Strasse')));
    expect(() => PersonalWord.fromMap({...word.toMap(), 'id': 'wrong'}),
        throwsFormatException);
    expect(() => PersonalWord.fromMap({...word.toMap(), 'schemaVersion': 2}),
        throwsFormatException);
  });
  test('state normalizes UTC and rejects invalid intervals', () {
    final state = LearningState(
        itemId: 'a',
        dueAt: DateTime(2026),
        intervalSeconds: 10,
        lapseCount: 0,
        schedulerVersion: 1);
    expect(state.dueAt.isUtc, true);
    expect(
        () => LearningState(
            itemId: 'a',
            dueAt: DateTime(2026),
            intervalSeconds: -1,
            lapseCount: 0,
            schedulerVersion: 1),
        throwsFormatException);
  });
  test('account storage isolates values and rejects stale account handles',
      () async {
    final dir = await Directory.systemTemp.createTemp('m01-account');
    try {
      Hive.init(dir.path);
      final box = await Hive.openBox('LocalDatabase');
      await box.put('UserName', 'unowned legacy value');
      AccountStore.activeUid = 'alice';
      final alice = AccountStore.current();
      expect(alice.get('UserName'), null);
      await alice.put('UserName', 'Alice');
      AccountStore.activeUid = 'bob';
      final bob = AccountStore.current();
      expect(bob.get('UserName'), null);
      expect(() => alice.get('UserName'), throwsStateError);
      expect(() => alice.put('UserName', 'wrong'), throwsStateError);
      await bob.put('UserName', 'Bob');
      AccountStore.activeUid = 'alice';
      expect(alice.get('UserName'), 'Alice');
      expect(box.get('UserName'), 'unowned legacy value');
    } finally {
      AccountStore.activeUid = null;
      await Hive.close();
      await dir.delete(recursive: true);
    }
  });
}
