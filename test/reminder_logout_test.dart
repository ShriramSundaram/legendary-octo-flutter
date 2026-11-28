import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/data/reminder_logout.dart';

void main() {
  test('logout still reaches Auth when reminder initialization throws',
      () async {
    var signedOut = false;
    final result = await signOutWithReminderCleanup(
        cleanup: () async => throw StateError('Reminder binding failed'),
        signOut: () async {
          signedOut = true;
        });
    expect(signedOut, true);
    expect(result, false);
  });
  test('Auth failure is still surfaced; it is not reported as signed out',
      () async {
    await expectLater(
        signOutWithReminderCleanup(
            cleanup: () async => true,
            signOut: () async => throw StateError('Auth failed')),
        throwsStateError);
  });
  test('broken saved settings do not skip suppression or emergency cleanup',
      () async {
    final calls = <String>[];
    final result = await cleanRemindersForSignOut(suppressRestore: () async {
      calls.add('suppress');
    }, disableSavedSettings: () async {
      calls.add('saved');
      throw StateError('Bad saved settings');
    }, emergencyDisable: () async {
      calls.add('native');
    });
    expect(calls, ['suppress', 'saved', 'native']);
    expect(result, true);
  });
  test('failed cleanup is reported accurately and still permits sign-out',
      () async {
    var signedOut = false;
    final result = await signOutWithReminderCleanup(
        cleanup: () => cleanRemindersForSignOut(
            suppressRestore: () async => throw StateError('Disk error'),
            disableSavedSettings: () async => throw StateError('Init error'),
            emergencyDisable: () async => throw StateError('Native error')),
        signOut: () async {
          signedOut = true;
        });
    expect(signedOut, true);
    expect(result, false);
  });
}
