import 'account_store.dart';
import 'dart:async';

final _reviewWrites = <Object, Future<void>>{};

/// Serialize local read/modify/write operations across screens for one account.
Future<T> serializedReviewUpdate<T>(
    ReviewStorage storage, Future<T> Function() action) async {
  final Object key =
      storage is AccountReviewStorage ? storage.account.uid : storage;
  final previous = _reviewWrites[key] ?? Future<void>.value();
  final gate = Completer<void>();
  _reviewWrites[key] = gate.future;
  await previous.catchError((Object _) {});
  try {
    return await action();
  } finally {
    gate.complete();
    if (identical(_reviewWrites[key], gate.future)) _reviewWrites.remove(key);
  }
}

abstract class ReviewStorage {
  Map<String, dynamic>? read();
  Future<void> write(Map<String, dynamic> value);
}

/// One Hive value atomically checkpoints scheduling and the session cursor.
class AccountReviewStorage implements ReviewStorage {
  final AccountStore account;
  AccountReviewStorage(this.account);
  factory AccountReviewStorage.current() =>
      AccountReviewStorage(AccountStore.current());
  static const storageKey = 'learningReviewV1';
  @override
  Map<String, dynamic>? read() {
    final value = account.get(storageKey);
    return value == null ? null : Map<String, dynamic>.from(value as Map);
  }

  @override
  Future<void> write(Map<String, dynamic> value) async {
    await account.put(storageKey, value);
    // Reject UI continuation after sign-out/switch, even if the write completed.
    account.containsKey(storageKey);
  }
}
