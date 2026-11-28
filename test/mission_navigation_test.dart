import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/learning_shell.dart';
import 'package:germanreminder/learning_hub_page.dart';
import 'package:germanreminder/mission_page.dart';
import 'package:germanreminder/data/practice_speech.dart';
import 'missions_test.dart' show pilotMissions, MemoryMissionStorage;

class NoVoice implements PracticeSpeech {
  @override
  Future<bool> prepare() async => false;
  @override
  Future<bool> speak(String text) async => false;
  @override
  Future<void> stop() async {}
}

void main() {
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('one Learn destination retains shared level and exposes Missions',
      (tester) async {
    var returnedHome = 0;
    await tester.pumpWidget(MaterialApp(
        home: LearningShell(
            home: const Scaffold(body: Text('Daily progress')),
            onHomeSelected: () => returnedHome++,
            learnBuilder: () => LearningHubPage(
                loadMissions: () async => pilotMissions(),
                missionStorage: MemoryMissionStorage(),
                wordsBuilder: (level) => Text('Words for $level')),
            wordsBuilder: () => const Text('Personal words'),
            profileBuilder: (_) => const Text('Preferences'))));
    await tap(tester, find.text('Learn'));
    expect(find.text('Learn'), findsOneWidget);
    await tap(tester, find.text('Missions'));
    expect(find.text('At the café'), findsOneWidget);
    await tap(tester, find.text('B2'));
    expect(find.textContaining('Reviewed B2 missions are being prepared'),
        findsOneWidget);
    await tap(tester, find.text('Words'));
    expect(find.text('Words for B2'), findsOneWidget);
    await tap(tester, find.text('Home'));
    expect(returnedHome, 1);
    await tap(tester, find.text('Learn'));
    expect(find.text('Words for B2'), findsOneWidget);
    expect(find.text('Start practice'), findsNothing);
  });
  testWidgets(
      'mission choices give feedback, resume and explicit listening fallback',
      (tester) async {
    final mission = pilotMissions().single, store = MemoryMissionStorage();
    await tester.pumpWidget(MaterialApp(
        home:
            MissionPage(mission: mission, storage: store, speech: NoVoice())));
    await tap(tester, find.text('Begin mission'));
    for (var i = 0; i < mission.steps.length; i++) {
      if (mission.steps[i].listening) {
        await tap(tester, find.text('Listen / replay'));
        expect(find.text('Text mode'), findsOneWidget);
        expect(find.text(mission.steps[i].prompt), findsOneWidget);
      }
      await tap(tester,
          find.text(mission.steps[i].choices[mission.steps[i].correct]));
      await tap(tester, find.text('Check response'));
      expect(find.text(mission.steps[i].explanation), findsOneWidget);
      await tap(
          tester,
          find.text(
              i == mission.steps.length - 1 ? 'Finish mission' : 'Continue'));
    }
    expect(find.text('Mission complete!'), findsOneWidget);
    expect(find.textContaining('This is not a listening-only score'),
        findsOneWidget);
    expect(store.value!['position'], 5);
  });
  testWidgets('pilot at 320px and 200 percent text keeps choices readable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: MissionPage(
            mission: pilotMissions().single,
            storage: MemoryMissionStorage(),
            speech: NoVoice())));
    await tap(tester, find.text('Begin mission'));
    await tap(
        tester, find.text(pilotMissions().single.steps.first.choices.first));
    await tap(tester, find.text('Check response'));
    await tap(tester, find.text('Continue'));
    expect(tester.takeException(), isNull);
  });
}
