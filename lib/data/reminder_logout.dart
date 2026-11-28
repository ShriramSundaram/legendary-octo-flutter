/// Cleanup is attempted fully, even if reminder initialization failed. The
/// authentication operation itself must never depend on a working timer UI.
Future<bool> cleanRemindersForSignOut({
  required Future<void> Function() suppressRestore,
  required Future<void> Function() disableSavedSettings,
  required Future<void> Function() emergencyDisable,
}) async {
  var suppressed = false, saved = false, stopped = false;
  try {
    await suppressRestore();
    suppressed = true;
  } catch (_) {}
  try {
    await disableSavedSettings();
    saved = true;
  } catch (_) {}
  try {
    await emergencyDisable();
    stopped = true;
  } catch (_) {}
  return stopped && (suppressed || saved);
}

Future<bool> signOutWithReminderCleanup({
  required Future<bool> Function() cleanup,
  required Future<void> Function() signOut,
}) async {
  var cleaned = false;
  try {
    cleaned = await cleanup();
  } catch (_) {}
  // Auth errors still propagate. A reminder error does not prevent sign-out.
  await signOut();
  return cleaned;
}
