import 'dart:convert';
import 'dart:async';
import 'content_catalog.dart';
import 'learning_progress.dart';
import 'account_store.dart';

class MissionStep {
  final String id, speaker, prompt, translation, explanation;
  final List<String> choices;
  final int correct;
  final bool listening;
  MissionStep(Map<String, dynamic> data)
      : id = data['id'] as String,
        speaker = data['speaker'] as String,
        prompt = data['prompt'] as String,
        translation = data['translation'] as String,
        explanation = data['explanation'] as String,
        choices = List<String>.unmodifiable(data['choices'] as List),
        correct = data['correct'] as int,
        listening = data['listening'] as bool {
    if ([id, speaker, prompt, translation, explanation]
            .any((s) => s.trim().isEmpty) ||
        choices.length < 2 ||
        choices.length > 4 ||
        choices.toSet().length != choices.length ||
        choices.any((s) => s.trim().isEmpty) ||
        correct < 0 ||
        correct >= choices.length) {
      throw const FormatException('Invalid mission step');
    }
  }
}

class Mission {
  final String id, level, status, title, emoji, objective, situation, topic;
  final int version, minutes;
  final List<MissionStep> steps;
  final List<String> usefulWords;
  Mission(Map<String, dynamic> data)
      : id = data['id'] as String,
        level = data['level'] as String,
        status = data['status'] as String,
        title = data['title'] as String,
        emoji = data['emoji'] as String,
        objective = data['objective'] as String,
        situation = data['situation'] as String,
        topic = data['topic'] as String,
        version = data['version'] as int,
        minutes = data['minutes'] as int,
        usefulWords = List<String>.unmodifiable(data['usefulWords'] as List),
        steps = List.unmodifiable((data['steps'] as List)
            .map((s) => MissionStep(Map<String, dynamic>.from(s)))) {
    if (!RegExp(r'^[a-z0-9_]{1,64}$').hasMatch(id) ||
        !contentLevels.contains(level) ||
        !['draft', 'published'].contains(status) ||
        version < 1 ||
        minutes < 1 ||
        steps.length < 1 ||
        steps.length > 10 ||
        steps.map((s) => s.id).toSet().length != steps.length ||
        [title, objective, situation, topic].any((s) => s.trim().isEmpty) ||
        (status == 'published' &&
            (data['reviewer'] is! String ||
                (data['reviewer'] as String).trim().isEmpty ||
                DateTime.tryParse('${data['reviewedAt']}') == null))) {
      throw const FormatException('Invalid or unsigned mission');
    }
  }
}

List<Mission> decodeMissions(String source,
    {bool preview = false, bool archive = false}) {
  final data = jsonDecode(source) as Map;
  if (data['schemaVersion'] != 1 || data['missions'] is! List)
    throw const FormatException('Unsupported missions');
  final all = (data['missions'] as List)
      .map((m) => Mission(Map<String, dynamic>.from(m)))
      .toList();
  if (all.map((m) => archive ? '${m.id}:${m.version}' : m.id).toSet().length !=
      all.length) throw const FormatException('Duplicate mission');
  return all.where((m) => m.status == 'published' || preview).toList();
}

abstract class MissionStorage {
  Map<String, dynamic>? read(String missionId);
  Future<void> write(Map<String, dynamic> value);
}

/// Only a choice-only revision may transparently upgrade an unfinished attempt.
bool canUpgradeMissionChoices(Mission old, Mission next) {
  if (old.id != next.id ||
      old.level != next.level ||
      old.steps.length != next.steps.length ||
      old.version >= next.version) return false;
  for (var i = 0; i < old.steps.length; i++) {
    final a = old.steps[i], b = next.steps[i];
    if (a.id != b.id ||
        a.prompt != b.prompt ||
        a.speaker != b.speaker ||
        a.translation != b.translation ||
        a.explanation != b.explanation ||
        a.listening != b.listening ||
        b.choices.length != a.choices.length + 1 ||
        !a.choices.every(b.choices.contains) ||
        a.choices[a.correct] != b.choices[b.correct]) return false;
  }
  return true;
}

class StaleMission implements Exception {}

final _missionWrites = <Object, Future<void>>{};

class AccountMissionStorage implements MissionStorage {
  final AccountStore account;
  AccountMissionStorage(this.account);
  Map<String, dynamic> _ledger() {
    final raw = account.get('missionSessionsV1');
    if (raw == null)
      return {
        'schemaVersion': 1,
        'latest': <String, dynamic>{},
        'attempts': <String, dynamic>{}
      };
    if (raw is! Map ||
        raw['schemaVersion'] != 1 ||
        raw['latest'] is! Map ||
        raw['attempts'] is! Map ||
        (raw['latest'] as Map).length > 100 ||
        (raw['attempts'] as Map).length > 1000) {
      throw const FormatException('Unsupported saved mission history');
    }
    for (final entry in (raw['latest'] as Map).entries) {
      final record = (raw['attempts'] as Map)[entry.value];
      if (record is! Map ||
          record['id'] != entry.value ||
          record['missionId'] != entry.key) {
        throw const FormatException('Invalid saved mission history');
      }
    }
    return Map<String, dynamic>.from(raw);
  }

  List<Map<String, dynamic>> history() => (_ledger()['attempts'] as Map)
      .values
      .map((r) => Map<String, dynamic>.from(r as Map))
      .toList();
  @override
  Map<String, dynamic>? read(String missionId) {
    final ledger = _ledger();
    final id = (ledger['latest'] as Map)[missionId];
    final value = id == null
        ? account.get('missionLatestV1:$missionId')
        : (ledger['attempts'] as Map)[id];
    return value == null ? null : Map<String, dynamic>.from(value as Map);
  }

  @override
  Future<void> write(Map<String, dynamic> value) async {
    final ledger = _ledger();
    final attempts = Map<String, dynamic>.from(ledger['attempts'] as Map);
    final legacy = account.get('missionLatestV1:${value['missionId']}');
    if (legacy is Map && legacy['id'] is String)
      attempts.putIfAbsent(legacy['id'] as String, () => legacy);
    attempts[value['id'] as String] = Map<String, dynamic>.from(value);
    final latest = {
      ...ledger['latest'] as Map,
      value['missionId']: value['id']
    };
    // Never discard an unsynced result just to start a replay. M06 will own
    // cloud archival/retention; a pilot reaching this bound keeps its data.
    if (attempts.length > 1000 || latest.length > 100)
      throw StateError(
          'Mission history is full; saved results were preserved.');
    await account.put('missionSessionsV1',
        {'schemaVersion': 1, 'latest': latest, 'attempts': attempts});
    account.containsKey('missionSessionsV1');
  }
}

class MissionController {
  final Mission mission;
  final MissionStorage storage;
  Map<String, dynamic>? attempt;
  Map<String, dynamic>? _replacedAttempt;
  bool _needsChoiceUpgrade = false;
  bool busy = false;
  static void validateSnapshot(Mission mission, Map<String, dynamic> data) {
    // Reuse the same full cursor/answer validation for historical goals.
    MissionController(mission, _SnapshotMissionStorage(data));
  }

  MissionController(this.mission, this.storage, {Mission? previousVersion}) {
    final saved = storage.read(mission.id);
    if (saved != null) {
      if (saved['contentVersion'] != mission.version &&
          previousVersion != null) {
        _validate(saved, definition: previousVersion);
        if (saved['position'] != previousVersion.steps.length) {
          if (!canUpgradeMissionChoices(previousVersion, mission)) {
            throw const FormatException(
                'Resume the previous mission version first');
          }
          final answers = <String, dynamic>{};
          for (var i = 0; i < (saved['answers'] as Map).length; i++) {
            final old = previousVersion.steps[i], next = mission.steps[i];
            final row =
                Map<String, dynamic>.from(saved['answers'][old.id] as Map);
            answers[next.id] = {
              ...row,
              'first': next.choices.indexOf(old.choices[row['first'] as int]),
              'choice': next.choices.indexOf(old.choices[row['choice'] as int])
            };
          }
          attempt = {
            ...saved,
            'contentVersion': mission.version,
            'answers': answers
          };
          _validate(attempt!);
          _needsChoiceUpgrade = true;
        } else {
          _replacedAttempt = saved;
        }
      } else {
        _validate(saved);
        attempt = saved;
      }
    }
  }
  void _validate(Map<String, dynamic> data, {Mission? definition}) {
    final mission = definition ?? this.mission;
    if (data['revision'] != null &&
        (data['revision'] is! int ||
            data['revision'] < 1 ||
            data['revision'] > 1000000000)) {
      throw const FormatException('Invalid mission revision');
    }
    if (data['schemaVersion'] != 1 ||
        data['missionId'] != mission.id ||
        data['contentVersion'] != mission.version ||
        data['id'] is! String ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(data['id']) ||
        data['position'] is! int ||
        data['position'] < 0 ||
        data['position'] > mission.steps.length ||
        data['feedback'] is! bool ||
        data['answers'] is! Map)
      throw const FormatException('Incompatible saved mission');
    final position = data['position'] as int;
    final answers = data['answers'] as Map;
    if (answers.length != position + (data['feedback'] == true ? 1 : 0) ||
        (position == mission.steps.length && data['feedback'] == true))
      throw const FormatException('Invalid mission cursor');
    for (var i = 0; i < answers.length; i++) {
      final step = mission.steps[i], row = answers[mission.steps[i].id];
      if (row is! Map ||
          row['first'] is! int ||
          row['choice'] is! int ||
          row['first'] < 0 ||
          row['first'] >= step.choices.length ||
          row['choice'] < 0 ||
          row['choice'] >= step.choices.length ||
          row['textMode'] is! bool)
        throw const FormatException('Invalid mission answer');
    }
  }

  int get position => attempt?['position'] as int? ?? 0;
  bool get complete => attempt != null && position == mission.steps.length;
  bool get feedback => attempt?['feedback'] == true;
  bool get canResume => attempt != null && !complete;
  Map get answers => attempt?['answers'] as Map? ?? {};
  int get firstCorrect => mission.steps
      .where((s) => (answers[s.id] as Map?)?['first'] == s.correct)
      .length;
  Future<void> _save(Map<String, dynamic> next) async {
    final expected = attempt ?? _replacedAttempt;
    final Object key = storage is AccountMissionStorage
        ? '${(storage as AccountMissionStorage).account.uid}:${mission.id}'
        : storage;
    final prior = _missionWrites[key] ?? Future<void>.value();
    final gate = Completer<void>();
    _missionWrites[key] = gate.future;
    await prior;
    try {
      final latest = storage.read(mission.id);
      if ((latest == null) != (expected == null) ||
          latest?['id'] != expected?['id'] ||
          latest?['revision'] != expected?['revision']) throw StaleMission();
      final value = {
        ...next,
        'revision': ((expected?['revision'] as int?) ?? 0) + 1
      };
      _validate(value);
      await storage.write(value);
      attempt = value;
      _replacedAttempt = null;
      _needsChoiceUpgrade = false;
    } finally {
      gate.complete();
      if (identical(_missionWrites[key], gate.future))
        _missionWrites.remove(key);
    }
  }

  Future<bool> begin() async {
    if (busy) return false;
    if (canResume && !_needsChoiceUpgrade) return true;
    busy = true;
    try {
      if (canResume) {
        await _save(attempt!);
        return true;
      }
      await _save({
        'schemaVersion': 1,
        'id': newReviewSessionId(),
        'missionId': mission.id,
        'contentVersion': mission.version,
        'level': mission.level,
        'position': 0,
        'feedback': false,
        'answers': <String, dynamic>{},
        'startedAt': DateTime.now().toUtc().toIso8601String()
      });
      return true;
    } finally {
      busy = false;
    }
  }

  Future<bool> submit(int choice,
      {required int expectedPosition,
      required bool textMode,
      bool retry = false}) async {
    if (busy ||
        attempt == null ||
        complete ||
        (feedback != retry) ||
        position != expectedPosition ||
        choice < 0 ||
        choice >= mission.steps[position].choices.length) return false;
    busy = true;
    try {
      final step = mission.steps[position];
      await _save({
        ...attempt!,
        'feedback': true,
        'answers': {
          ...answers,
          step.id: {
            'first': (answers[step.id] as Map?)?['first'] ?? choice,
            'choice': choice,
            'textMode': textMode
          }
        }
      });
      return true;
    } finally {
      busy = false;
    }
  }

  Future<bool> advance({required int expectedPosition}) async {
    if (busy || !feedback || complete || position != expectedPosition)
      return false;
    busy = true;
    try {
      await _save({
        ...attempt!,
        'position': position + 1,
        'feedback': false,
        if (position + 1 == mission.steps.length)
          'completedAt': DateTime.now().toUtc().toIso8601String()
      });
      return true;
    } finally {
      busy = false;
    }
  }
}

class _SnapshotMissionStorage implements MissionStorage {
  final Map<String, dynamic> data;
  _SnapshotMissionStorage(this.data);
  @override
  Map<String, dynamic>? read(String missionId) => data;
  @override
  Future<void> write(Map<String, dynamic> value) =>
      throw UnsupportedError('Read only');
}
