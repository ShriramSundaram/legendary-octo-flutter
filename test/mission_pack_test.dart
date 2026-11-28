import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/data/content_catalog.dart';
import 'package:germanreminder/data/missions.dart';
import 'package:germanreminder/data/offline_vocabulary.dart';
import 'package:germanreminder/data/review_controller.dart';
import 'package:germanreminder/data/review_scheduler.dart';
import 'package:germanreminder/mission_review_goal.dart';
import 'package:germanreminder/mission_goals_panel.dart';
import 'package:germanreminder/vocabulary_browser_widgets.dart';
import 'missions_test.dart' show pilotMissions, MemoryMissionStorage;
import 'review_test_support.dart';

List<Mission> expandedMissions() =>
    decodeMissions(File('assets/missions_catalog_v1.json').readAsStringSync(),
        preview: true);
ContentCatalog expandedWords() => ContentCatalog.combine([
      ContentCatalog.decode(
          File('assets/content_catalog_v1.json').readAsStringSync()),
      ContentCatalog.decode(
          File('assets/mission_vocabulary_v1.json').readAsStringSync()),
    ], includeDrafts: true);
Future<void> finish(MissionController c) async {
  while (!c.complete) {
    await c.submit(c.mission.steps[c.position].correct,
        expectedPosition: c.position, textMode: true);
    await c.advance(expectedPosition: c.position);
  }
}

void main() {
  test(
      'choice-only upgrade preserves saved place, answer text and first-choice score',
      () async {
    final archived = decodeMissions(
        File('assets/missions_archive_v1.json').readAsStringSync(),
        preview: true,
        archive: true);
    final old = archived.firstWhere((m) =>
        m.id == 'cafe_a1' &&
        m.steps.length == 10 &&
        m.steps.first.choices.length == 2);
    final next = expandedMissions().firstWhere((m) => m.id == old.id);
    final storage = MemoryMissionStorage();
    final c = MissionController(old, storage);
    await c.begin();
    for (var i = 0; i < 3; i++) {
      await c.submit(
          i == 1 ? (old.steps[i].correct + 1) % 2 : old.steps[i].correct,
          expectedPosition: i,
          textMode: true);
      if (i < 2) await c.advance(expectedPosition: i);
    }
    final id = c.attempt!['id'];
    expect(c.firstCorrect, 2);
    final upgraded = MissionController(next, storage, previousVersion: old);
    expect(upgraded.position, 2);
    expect(upgraded.feedback, true);
    expect(upgraded.firstCorrect, 2);
    for (var i = 0; i < 3; i++) {
      final before = c.answers[old.steps[i].id] as Map;
      final after = upgraded.answers[next.steps[i].id] as Map;
      expect(next.steps[i].choices[after['first']],
          old.steps[i].choices[before['first']]);
    }
    storage.fail = true;
    await expectLater(upgraded.begin(), throwsStateError);
    expect(storage.value!['contentVersion'], old.version);
    storage.fail = false;
    await upgraded.begin();
    expect(storage.value!['id'], id);
    expect(storage.value!['contentVersion'], next.version);
    await upgraded.advance(expectedPosition: 2);
    expect(MissionController(next, storage).position, 3);
  });
  test(
      'six levels each have five ten-exchange missions and twenty new linked entries',
      () {
    final missions = expandedMissions(), catalog = expandedWords();
    final pack = ContentCatalog.decode(
        File('assets/mission_vocabulary_v1.json').readAsStringSync());
    expect(missions.length, 30);
    expect(pack.words.length, 120);
    for (final level in contentLevels) {
      expect(missions.where((m) => m.level == level).length, 5);
      expect(pack.words.where((w) => w.item.level == level).length, 20);
    }
    for (final m in missions) {
      expect(m.steps.length, 10);
      expect(
          m.steps.every(
              (s) => s.choices.length == 3 && s.choices.toSet().length == 3),
          isTrue);
      expect(m.steps.map((s) => s.correct).toSet(), {0, 1, 2});
      expect(m.steps.where((s) => s.listening).length, 2);
      expect(m.usefulWords.toSet().length, 4);
      expect(
          m.usefulWords.every((id) => catalog.words
              .any((w) => w.item.id == id && w.item.level == m.level)),
          isTrue);
    }
    final publicCatalog = ContentCatalog.combine([catalog]);
    expect(publicCatalog.words.length, 389);
    final offline = OfflineVocabulary.decode(
        File('assets/content_catalog_v1.json').readAsStringSync(),
        File('assets/legacy_vocabulary_v1.json').readAsStringSync(),
        supplementalSource:
            File('assets/mission_vocabulary_v1.json').readAsStringSync(),
        includeDrafts: true);
    expect(offline.words.where((w) => w.preview), isEmpty);
    expect(offline.words.length, 1448);
  });
  test(
      'unfinished five-step mission resumes unchanged; completed version starts expanded attempt',
      () async {
    final old = pilotMissions().single,
        current = expandedMissions().firstWhere((m) => m.id == old.id);
    final storage = MemoryMissionStorage();
    final original = MissionController(old, storage);
    await original.begin();
    final id = original.attempt!['id'];
    await original.submit(0, expectedPosition: 0, textMode: true);
    expect(() => MissionController(current, storage, previousVersion: old),
        throwsFormatException);
    final resumed = MissionController(old, storage);
    expect(resumed.attempt!['id'], id);
    await resumed.advance(expectedPosition: 0);
    await finish(resumed);
    final expanded = MissionController(current, storage, previousVersion: old);
    expect(expanded.attempt, isNull);
    await expanded.begin();
    expect(expanded.attempt!['id'], isNot(id));
    expect(expanded.attempt!['contentVersion'], current.version);
    expect(expanded.position, 0);
  });
  test(
      'mission goal counts persisted recall only and survives resume and a new day',
      () async {
    final mission = expandedMissions().first;
    final storage = MemoryReviewStorage();
    var now = DateTime.utc(2026, 11, 27, 10);
    final attempt = <String, dynamic>{'completedAt': now.toIso8601String()};
    final c = ReviewController(expandedWords(), storage,
        previewDrafts: true,
        onlyItemIds: mission.usefulWords.toSet(),
        clock: () => now);
    expect(missionReviewedCount(mission, attempt, storage.read()), 0);
    await c.start(mission.level, null);
    expect(c.session!.ids.toSet(), mission.usefulWords.toSet());
    expect(missionReviewedCount(mission, attempt, storage.read()), 0);
    await c.answer(RecallAnswer.remembered,
        expectedPosition: 0, expectedItemId: c.current!.item.id);
    final resumed = ReviewController(expandedWords(), storage,
        previewDrafts: true, clock: () => now);
    expect(resumed.canResume, isTrue);
    expect(resumed.session!.practiceOnly, isTrue);
    while (!resumed.session!.complete) {
      await resumed.answer(RecallAnswer.again,
          expectedPosition: resumed.session!.position,
          expectedItemId: resumed.current!.item.id);
    }
    expect(missionReviewedCount(mission, attempt, storage.read()), 4);
    expect(resumed.progress.on(now.toLocal()).reviews, 4);
    now = now.add(const Duration(days: 1));
    expect(missionReviewedCount(mission, attempt, storage.read()), 4);
    final reopened = ReviewController(expandedWords(), storage,
        previewDrafts: true, clock: () => now);
    expect(reopened.progress.on(now.toLocal()).reviews, 0);
  });
  test(
      'early mission review preserves due interval and existing unfinished session',
      () async {
    final storage = MemoryReviewStorage();
    var now = reviewNow;
    final c =
        ReviewController(reviewCatalog(count: 2), storage, clock: () => now);
    await c.start('A1', null);
    final originalId = c.session!.id;
    final targeted = ReviewController(reviewCatalog(count: 2), storage,
        onlyItemIds: {'word_01'}, clock: () => now);
    await targeted.start('A1', null);
    expect(targeted.session!.id, originalId);
    while (!targeted.session!.complete) {
      await targeted.answer(RecallAnswer.remembered,
          expectedPosition: targeted.session!.position,
          expectedItemId: targeted.current!.item.id);
    }
    final due = targeted.states['word_01']!.dueAt;
    now = now.add(const Duration(minutes: 1));
    await targeted.start('A1', null);
    await targeted.answer(RecallAnswer.remembered,
        expectedPosition: 0, expectedItemId: 'word_01');
    expect(targeted.states['word_01']!.dueAt, due);
    expect(targeted.states['word_01']!.lastAttempt, now);
  });
  test('replaying a mission keeps the previous completed review goal available',
      () async {
    final mission = expandedMissions().first, storage = MemoryMissionStorage();
    final c = MissionController(mission, storage);
    await c.begin();
    await finish(c);
    final completed = Map<String, dynamic>.from(c.attempt!);
    await c.begin();
    final goals = completedMissionGoals([mission], [completed, c.attempt!]);
    expect(goals.single.attempt['id'], completed['id']);
    expect(missionReviewedCount(mission, goals.single.attempt, null), 0);
  });
  testWidgets(
      'shared vocabulary cards select, speak and fit narrow large-text view',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? selected, spoken;
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: Scaffold(
            body: VocabularyCards(
                entries: const [
              VocabularyEntry('one', 'der Becher - cup', preview: true)
            ],
                selectedId: null,
                onSelect: (id) => selected = id,
                onSpeak: (text) => spoken = text))));
    await tester.tap(find.text('der Becher - cup'));
    await tester.tap(find.byTooltip('Speak'));
    expect(selected, 'one');
    expect(spoken, 'der Becher - cup');
    expect(find.text('Preview · Review pending'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'completed goal stays visible after reopening without awarding activity',
      (tester) async {
    final storage = MemoryReviewStorage(), mission = expandedMissions().first;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MissionReviewGoal(
                mission: mission,
                attempt: {'completedAt': reviewNow.toIso8601String()},
                storage: storage))));
    expect(find.text('🎯 Your next review goal'), findsOneWidget);
    expect(find.textContaining('0 / 4'), findsOneWidget);
    expect(storage.writes, 0);
  });
}
