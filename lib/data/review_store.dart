import 'account_store.dart';

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
