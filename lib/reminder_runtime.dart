import 'package:hive/hive.dart';
import 'data/account_store.dart';
import 'data/reminder_controller.dart';
import 'data/reminder_models.dart';
import 'notification_api.dart';

/// One serialized device scheduler, even if several home/profile routes exist.
class ReminderRuntime {
  static ReminderController? _controller;
  static String? _uid;
  static Future<void> _binding = Future.value();
  static String? initializationError;
  static Future<void> bindAccount(String? uid) {
    final bind = _binding.catchError((Object _) {}).then((_) async {
      if (uid != AccountStore.activeUid) return;
      if (_uid == uid && _controller != null && !_controller!.closed) return;
      final old = _controller;
      old?.closed = true;
      await old?.idle;
      _controller = null;
      _uid = uid;
      initializationError = null;
      final box = Hive.box('LocalDatabase');
      final owner = uid == null ? null : reminderOwner(uid);
      if (box.get('reminderDeviceOwnerV1') != owner || uid == null) {
        for (final id in [0, reminderTimerId, ...reminderWeeklyIds]) {
          await NotificationApi.instance.cancel(id);
        }
      }
      await NotificationApi.instance.bindOwner(owner);
      await box.put('reminderDeviceOwnerV1', owner);
      if (uid == null || uid != AccountStore.activeUid) return;
      try {
        _controller = ReminderController(
            AccountReminderStorage(AccountStore(box, uid)),
            NotificationApi.instance);
        if (box.get('reminderSuppressed:' + owner!) == true)
          await _controller!.disableAll();
        await _controller!.refresh();
      } catch (_) {
        for (final id in [reminderTimerId, ...reminderWeeklyIds]) {
          try {
            await NotificationApi.instance.cancel(id);
          } catch (_) {}
        }
        try {
          await NotificationApi.instance.bindOwner(null);
        } catch (_) {}
        initializationError =
            'Could not restore reminder settings. Your saved settings have not been reset.';
        rethrow;
      }
    });
    _binding = bind;
    return bind;
  }

  static Future<ReminderController> current() async {
    await _binding;
    final current = _controller;
    if (current == null || current.closed || _uid != AccountStore.activeUid)
      throw StateError(initializationError ?? 'Sign in to manage reminders.');
    return current;
  }

  static Future<void> disableBeforeSignOut() async {
    final uid = AccountStore.activeUid;
    if (uid != null)
      await Hive.box('LocalDatabase')
          .put('reminderSuppressed:' + reminderOwner(uid), true);
    try {
      final current = await ReminderRuntime.current();
      await current.disableAll();
    } catch (_) {
      /* Native cancellation still runs if stored preferences are corrupt. */
    }
    for (final id in [reminderTimerId, ...reminderWeeklyIds]) {
      await NotificationApi.instance.cancel(id);
    }
    await NotificationApi.instance.bindOwner(null);
    NotificationApi.pendingPayload = null;
  }
}
