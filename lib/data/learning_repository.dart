import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'learning_models.dart';
import 'legacy_migration.dart';

class ContentPage {
  final List<ContentItem> items;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
  const ContentPage(this.items, this.cursor, this.hasMore);
}

class ContentRepository {
  final FirebaseFirestore db;
  ContentRepository(this.db);
  Future<ContentPage> published(
      {DocumentSnapshot<Map<String, dynamic>>? after}) async {
    Query<Map<String, dynamic>> query = db
        .collection('contentV1')
        .where('editorialStatus', isEqualTo: 'published')
        .orderBy(FieldPath.documentId)
        .limit(50);
    if (after != null) query = query.startAfterDocument(after);
    final result = await query.get();
    final items = result.docs.map((doc) {
      final item = ContentItem.fromMap(doc.data());
      if (item.id != doc.id)
        throw const FormatException('Content ID mismatch.');
      return item;
    }).toList();
    return ContentPage(items, result.docs.isEmpty ? null : result.docs.last,
        result.docs.length == 50);
  }
}

class WordPage {
  final List<PersonalWord> words;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
  const WordPage(this.words, this.cursor, this.hasMore);
}

class LearningRepository implements MigrationStore {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  final String uid;
  LearningRepository({required this.db, required this.auth, required this.uid});
  factory LearningRepository.current() {
    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('Please sign in.');
    return LearningRepository(
        db: FirebaseFirestore.instance, auth: auth, uid: uid);
  }
  void _checkAccount() {
    if (auth.currentUser?.uid != uid)
      throw StateError('Account changed. Please reopen this screen.');
  }

  DocumentReference<Map<String, dynamic>> get _user =>
      db.collection('User').doc(uid);
  CollectionReference<Map<String, dynamic>> get _words =>
      _user.collection('personalWordsV1');

  Future<MigrationReport> migrate() async {
    _checkAccount();
    final snapshot = await _user.get(const GetOptions(source: Source.server));
    _checkAccount();
    return migrateLegacy(snapshot.data()?['wordStorage'], this);
  }

  @override
  Future<void> ensureWord(PersonalWord word) async {
    _checkAccount();
    PersonalWord.fromMap(word.toMap());
    await db.runTransaction((transaction) async {
      _checkAccount();
      final ref = _words.doc(word.id);
      final existing = await transaction.get(ref);
      _checkAccount();
      if (!existing.exists) {
        transaction.set(ref, word.toMap());
      } else if (PersonalWord.fromMap(existing.data()!).lemma != word.lemma) {
        throw StateError('Word identity conflict; original preserved.');
      }
    });
  }

  @override
  Future<PersonalWord?> readWord(String id) async {
    _checkAccount();
    final doc =
        await _words.doc(id).get(const GetOptions(source: Source.server));
    _checkAccount();
    return doc.exists ? PersonalWord.fromMap(doc.data()!) : null;
  }

  @override
  Future<void> checkpoint(Map<String, dynamic> report) async {
    _checkAccount();
    await _user.collection('migrations').doc('personalWordsV1').set(report);
  }

  Future<WordPage> page({DocumentSnapshot<Map<String, dynamic>>? after}) async {
    _checkAccount();
    Query<Map<String, dynamic>> query =
        _words.orderBy(FieldPath.documentId).limit(50);
    if (after != null) query = query.startAfterDocument(after);
    final result = await query.get();
    _checkAccount();
    final words = result.docs.map((doc) {
      final word = PersonalWord.fromMap(doc.data());
      if (word.id != doc.id)
        throw const FormatException('Invalid document ID.');
      return word;
    }).toList();
    return WordPage(words, result.docs.isEmpty ? null : result.docs.last,
        result.docs.length == 50);
  }

  Future<void> saveState(LearningState state) async {
    _checkAccount();
    await _user.collection('learningStateV1').doc(state.itemId).set({
      'schemaVersion': 1,
      'itemId': state.itemId,
      'dueAt': Timestamp.fromDate(state.dueAt),
      'lastAttempt': state.lastAttempt == null
          ? null
          : Timestamp.fromDate(state.lastAttempt!),
      'intervalSeconds': state.intervalSeconds,
      'lapseCount': state.lapseCount,
      'schedulerVersion': state.schedulerVersion,
    });
  }

  Future<List<LearningState>> due(DateTime now) async {
    _checkAccount();
    final result = await _user
        .collection('learningStateV1')
        .where('dueAt', isLessThanOrEqualTo: Timestamp.fromDate(now.toUtc()))
        .orderBy('dueAt')
        .limit(50)
        .get();
    _checkAccount();
    return result.docs.map((doc) {
      final data = doc.data();
      if (data['schemaVersion'] != 1 ||
          data['itemId'] != doc.id ||
          data['dueAt'] is! Timestamp ||
          (data['lastAttempt'] != null && data['lastAttempt'] is! Timestamp) ||
          data['intervalSeconds'] is! int ||
          data['lapseCount'] is! int ||
          data['schedulerVersion'] is! int) {
        throw const FormatException('Invalid learning state.');
      }
      return LearningState(
          itemId: doc.id,
          dueAt: (data['dueAt'] as Timestamp).toDate(),
          lastAttempt: (data['lastAttempt'] as Timestamp?)?.toDate(),
          intervalSeconds: data['intervalSeconds'] as int,
          lapseCount: data['lapseCount'] as int,
          schedulerVersion: data['schedulerVersion'] as int);
    }).toList();
  }
}
