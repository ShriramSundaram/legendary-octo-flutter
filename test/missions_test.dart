import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/data/missions.dart';

List<Mission> pilotMissions() =>
    decodeMissions(File('assets/missions_archive_v1.json').readAsStringSync(),
            preview: true, archive: true)
        .where((m) => m.id == 'cafe_a1' && m.version == 1)
        .toList();

class MemoryMissionStorage implements MissionStorage {
  Map<String, dynamic>? value;
  int writes = 0;
  bool fail = false;
  Completer<void>? gate;
  @override
  Map<String, dynamic>? read(String id) =>
      value == null ? null : jsonDecode(jsonEncode(value));
  @override
  Future<void> write(Map<String, dynamic> next) async {
    if (gate != null) await gate!.future;
    if (fail) throw StateError('Write failed');
    value = jsonDecode(jsonEncode(next));
    writes++;
  }
}

void main() {
  test('unapproved pilot cannot appear in published missions', () {
    final archived =
        jsonDecode(File('assets/missions_archive_v1.json').readAsStringSync());
    final source = jsonEncode({
      'schemaVersion': 1,
      'missions': (archived['missions'] as List)
          .where((m) => m['id'] == 'cafe_a1' && m['version'] == 1)
          .toList()
    });
    expect(decodeMissions(source), isEmpty);
    expect(pilotMissions().single.steps.length, 5);
    final data = jsonDecode(source);
    data['missions'][0]['status'] = 'published';
    expect(() => decodeMissions(jsonEncode(data)), throwsFormatException);
  });
  test('submitted choice and feedback survive restart; next step resumes once',
      () async {
    final store = MemoryMissionStorage(), mission = pilotMissions().single;
    final c = MissionController(mission, store);
    await c.begin();
    await c.submit(0, expectedPosition: 0, textMode: false);
    var resumed = MissionController(mission, store);
    expect(resumed.feedback, isTrue);
    expect(resumed.position, 0);
    expect(resumed.answers['order']['first'], 0);
    await resumed.advance(expectedPosition: 0);
    resumed = MissionController(mission, store);
    expect(resumed.position, 1);
    expect(resumed.feedback, isFalse);
    expect(await resumed.advance(expectedPosition: 0), isFalse);
  });
  test('retry keeps the first choice and failed saves keep the current step',
      () async {
    final store = MemoryMissionStorage(), mission = pilotMissions().single;
    final c = MissionController(mission, store);
    await c.begin();
    store.fail = true;
    await expectLater(
        c.submit(1, expectedPosition: 0, textMode: false), throwsStateError);
    expect(c.feedback, isFalse);
    expect(c.answers, isEmpty);
    store.fail = false;
    await c.submit(1, expectedPosition: 0, textMode: false);
    await c.submit(0, expectedPosition: 0, textMode: false, retry: true);
    expect(c.answers['order']['first'], 1);
    expect(c.answers['order']['choice'], 0);
    expect(c.firstCorrect, 0);
  });
  test('a delayed save rejects double submit and replay creates a new attempt',
      () async {
    final store = MemoryMissionStorage(), mission = pilotMissions().single;
    final c = MissionController(mission, store);
    await c.begin();
    final firstId = c.attempt!['id'];
    store.gate = Completer<void>();
    final first = c.submit(0, expectedPosition: 0, textMode: false);
    expect(await c.submit(1, expectedPosition: 0, textMode: false), isFalse);
    store.gate!.complete();
    await first;
    store.gate = null;
    await c.advance(expectedPosition: 0);
    while (!c.complete) {
      await c.submit(mission.steps[c.position].correct,
          expectedPosition: c.position, textMode: true);
      await c.advance(expectedPosition: c.position);
    }
    final count = store.writes;
    expect(await c.advance(expectedPosition: 4), isFalse);
    expect(store.writes, count);
    await c.begin();
    expect(c.attempt!['id'], isNot(firstId));
    expect(c.position, 0);
  });
  test('content version changes do not overwrite incompatible saved attempts',
      () async {
    final store = MemoryMissionStorage(), mission = pilotMissions().single;
    await MissionController(mission, store).begin();
    store.value!['contentVersion'] = 999;
    final writes = store.writes;
    expect(() => MissionController(mission, store), throwsFormatException);
    expect(store.value!['contentVersion'], 999);
    expect(store.writes, writes);
  });
  test('a stale mission screen cannot overwrite a newer saved cursor',
      () async {
    final store = MemoryMissionStorage(), mission = pilotMissions().single;
    final first = MissionController(mission, store);
    await first.begin();
    await first.submit(0, expectedPosition: 0, textMode: false);
    final stale = MissionController(mission, store);
    await first.advance(expectedPosition: 0);
    await expectLater(
        stale.advance(expectedPosition: 0), throwsA(isA<StaleMission>()));
    expect(store.value!['position'], 1);
  });
}
