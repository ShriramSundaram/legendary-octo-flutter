import 'account_store.dart';

/// Device-local, account-scoped summaries. M06 owns cloud synchronization.
class PracticeHistory {
  final AccountStore account;
  PracticeHistory(this.account);
  Future<void> save(Map<String, dynamic> summary) async {
    final previous = account.get('practiceSessionsV1', defaultValue: const []);
    final rows = (previous as List)
        .where((r) => r is Map && r['id'] != summary['id'])
        .toList();
    rows.add(Map<String, dynamic>.of(summary));
    await account.put('practiceSessionsV1',
        rows.skip(rows.length > 50 ? rows.length - 50 : 0).toList());
    account.get('practiceSessionsV1');
  }
}
