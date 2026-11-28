import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:germanreminder/data/account_store.dart';
import 'package:germanreminder/data/missions.dart';
import 'missions_test.dart' show pilotMissions;
import 'mission_pack_test.dart' show expandedMissions;

void main() {
  test(
      'replay retains the completed attempt; reopening and account switching stay isolated',
      () async {
    final folder = await Directory.systemTemp.createTemp('m11-account-');
    Hive.init(folder.path);
    var box = await Hive.openBox('missions');
    try {
      AccountStore.activeUid = 'A';
      var storeA = AccountMissionStorage(AccountStore(box, 'A'));
      final mission = pilotMissions().single;
      final c = MissionController(mission, storeA);
      final expanded = expandedMissions().firstWhere((m) => m.id == mission.id);
      await c.begin();
      final completedId = c.attempt!['id'];
      while (!c.complete) {
        await c.submit(mission.steps[c.position].correct,
            expectedPosition: c.position, textMode: true);
        await c.advance(expectedPosition: c.position);
      }
      await MissionController(expanded, storeA, previousVersion: mission)
          .begin();
      expect(storeA.history().length, 2);
      expect(
          storeA
              .history()
              .singleWhere((r) => r['id'] == completedId)['position'],
          5);
      AccountStore.activeUid = 'B';
      final storeB = AccountMissionStorage(AccountStore(box, 'B'));
      expect(storeB.history(), isEmpty);
      expect(storeB.read(mission.id), isNull);
      expect(() => storeA.read(mission.id), throwsStateError);
      await expectLater(storeA.write(c.attempt!), throwsStateError);
      await box.close();
      box = await Hive.openBox('missions');
      AccountStore.activeUid = 'A';
      storeA = AccountMissionStorage(AccountStore(box, 'A'));
      expect(storeA.history().length, 2);
      expect(MissionController(expanded, storeA).canResume, isTrue);
      expect(storeA.read(mission.id)!['position'], 0);
    } finally {
      AccountStore.activeUid = null;
      await box.close();
      await folder.delete(recursive: true);
    }
  });
}
