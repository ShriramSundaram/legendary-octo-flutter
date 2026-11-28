import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:germanreminder/data/learning_audio.dart';
import 'package:germanreminder/mission_page.dart';
import 'package:germanreminder/learning_sound_settings.dart';
import 'missions_test.dart' show pilotMissions, MemoryMissionStorage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LearningAudio.channel, (call) async {
      calls.add(call);
      return null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(LearningAudio.channel, null));
  test('distinct confirmed outcomes reach native audio without score mutations',
      () async {
    final audio = LearningAudio();
    for (final event in [
      LearningCue.correct,
      LearningCue.wrong,
      LearningCue.remembered,
      LearningCue.again
    ]) {
      await audio.play(event);
    }
    expect(calls.map((c) => (c.arguments as Map)['event']).toList(),
        ['correct', 'wrong', 'remembered', 'again']);
  });
  test('mute settings persist and suppress both kinds of feedback', () async {
    final audio = LearningAudio();
    await audio.configure(soundEffects: false, voiceCues: false);
    calls.clear();
    final reopened = LearningAudio();
    await reopened.play(LearningCue.testIntro);
    expect(calls, isEmpty);
    expect(reopened.sounds, false);
    expect(reopened.spoken, false);
  });
  test('voice cues can be disabled independently of answer chimes', () async {
    final audio = LearningAudio();
    await audio.configure(voiceCues: false);
    calls.clear();
    await audio.play(LearningCue.resumeIntro);
    expect(calls.single.arguments,
        {'event': 'resumeIntro', 'sounds': true, 'spoken': false});
  });
  test('stop cancels an introduction waiting on preference loading', () async {
    final audio = LearningAudio();
    final play = audio.play(LearningCue.practiceIntro);
    await audio.stop();
    await play;
    expect(calls.where((c) => c.method == 'play'), isEmpty);
  });
  test('missing audio platform never fails a learning action', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LearningAudio.channel,
            (call) async => throw PlatformException(code: 'no_audio'));
    await LearningAudio().play(LearningCue.correct);
    await LearningAudio().stop();
  });
  testWidgets(
      'mission outcome sounds follow saved submissions, never selections or failed writes',
      (tester) async {
    final mission = pilotMissions().single, storage = MemoryMissionStorage();
    await tester.pumpWidget(
        MaterialApp(home: MissionPage(mission: mission, storage: storage)));
    Future<void> tap(String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    List<String> outcomes() => calls
        .where((c) => c.method == 'play')
        .map((c) => (c.arguments as Map)['event'] as String)
        .where((e) => e == 'correct' || e == 'wrong')
        .toList();
    await tap('Begin mission');
    final step = mission.steps.first;
    final wrong = (step.correct + 1) % step.choices.length;
    await tap(step.choices[wrong]);
    expect(outcomes(), isEmpty);
    storage.fail = true;
    await tap('Check response');
    expect(outcomes(), isEmpty);
    storage.fail = false;
    await tap('Check response');
    expect(outcomes(), ['wrong']);
    await tap('Try another reply');
    await tap(step.choices[step.correct]);
    await tap('Check response');
    expect(outcomes(), ['wrong', 'correct']);
    expect((storage.value!['answers'] as Map)[step.id]['first'], wrong);
  });
  testWidgets(
      'Profile previews exercise real outcome events and respect the sound switch',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: LearningSoundSettings(audio: LearningAudio())))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Learning audio'));
    await tester.pumpAndSettle();
    for (final title in ['Preview correct sound', 'Preview wrong sound']) {
      await tester.ensureVisible(find.text(title));
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
    }
    final events = calls
        .where((c) => c.method == 'play')
        .map((c) => (c.arguments as Map)['event']);
    expect(events, containsAll(['correct', 'wrong']));
    await tester.ensureVisible(find.text('Button and answer sounds'));
    await tester.tap(find.text('Button and answer sounds'));
    await tester.pumpAndSettle();
    final preview = find.ancestor(
        of: find.text('Preview correct sound'),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton));
    expect(tester.widget<OutlinedButton>(preview).onPressed, isNull);
  });
}
