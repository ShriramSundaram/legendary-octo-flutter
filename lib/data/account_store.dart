import 'dart:convert';
import 'package:hive/hive.dart';

/// The old unscoped keys are retained for manual recovery, never assigned to
/// whichever account happens to sign in first after an upgrade.
class AccountStore {
  static String? activeUid;
  final String uid;
  final Box box;
  AccountStore(this.box, this.uid);
  factory AccountStore.current() {
    final uid = activeUid;
    if (uid == null) throw StateError('No active account.');
    return AccountStore(Hive.box('LocalDatabase'), uid);
  }
  String key(String name) =>
      'account_v1:${base64Url.encode(utf8.encode(uid))}:$name';
  void _check() {
    if (activeUid != uid) throw StateError('Account changed.');
  }

  bool containsKey(String name) {
    _check();
    return box.containsKey(key(name));
  }

  dynamic get(String name, {dynamic defaultValue}) {
    _check();
    return box.get(key(name), defaultValue: defaultValue);
  }

  Future<void> put(String name, dynamic value) {
    _check();
    return box.put(key(name), value);
  }
}
