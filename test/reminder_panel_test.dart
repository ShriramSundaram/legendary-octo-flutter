import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:germanreminder/data/reminder_controller.dart';
import 'package:germanreminder/reminder_panel.dart';
import 'reminder_test_support.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  Future<void> tap(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('new timer offers presets and durable pause resume cancel',
      (tester) async {
    final store = MemoryReminderStorage();
    final backend = FakeReminderBackend();
    final controller = ReminderController(store, backend);
    await controller.refresh();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: ReminderPanel(
                    level: 'A1', word: 'das Haus', controller: controller)))));
    await tester.pumpAndSettle();
    await tap(tester, '5 min');
    await tap(tester, 'Start timer');
    expect(backend.jobs.keys.toSet(), {2100});
    await tap(tester, 'Pause');
    expect(controller.settings.paused, true);
    expect(backend.jobs, isEmpty);
    await tap(tester, 'Resume');
    expect(backend.jobs.containsKey(2100), true);
    await tap(tester, 'Cancel timer');
    expect(controller.settings.hasTimer, false);
    expect(backend.jobs, isEmpty);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets(
      'daily opt-in is explicit and disabled weekdays cannot be saved empty',
      (tester) async {
    final backend = FakeReminderBackend();
    final controller = ReminderController(MemoryReminderStorage(), backend);
    await controller.refresh();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: ReminderPanel(level: 'A1', controller: controller)))));
    await tester.pumpAndSettle();
    expect(backend.requests, 0);
    await tap(tester, 'Make it a habit');
    await tap(tester, 'Repeat study reminders');
    for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
      await tap(tester, day);
    expect(find.text('Choose at least one day.'), findsOneWidget);
    final save = tester.widget<FilledButton>(find
        .ancestor(
            of: find.text('Save schedule'),
            matching:
                find.byWidgetPredicate((widget) => widget is FilledButton))
        .first);
    expect(save.onPressed, null);
    expect(backend.jobs, isEmpty);
    await tap(tester, 'Mon');
    await tap(tester, 'Save schedule');
    expect(backend.jobs.keys.toSet(), {2101});
    expect(backend.requests, 1);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  for (final width in [240.0, 320.0, 800.0])
    for (final scale in [1.0, 2.0]) {
      testWidgets(
          'timer and day controls fit width $width at text scale $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller =
            ReminderController(MemoryReminderStorage(), FakeReminderBackend());
        await controller.refresh();
        await tester.pumpWidget(MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: Scaffold(
                body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child:
                        ReminderPanel(level: 'A1', controller: controller)))));
        await tester.pumpAndSettle();
        await tap(tester, 'Make it a habit');
        await tester.ensureVisible(find.text('Save schedule'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), null);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      });
    }
}
