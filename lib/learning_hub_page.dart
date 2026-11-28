import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/account_store.dart';
import 'data/content_catalog.dart';
import 'data/missions.dart';
import 'content_library_page.dart';
import 'mission_page.dart';

class LearningHubPage extends StatefulWidget {
  const LearningHubPage(
      {super.key, this.loadMissions, this.missionStorage, this.wordsBuilder});
  final Future<List<Mission>> Function()? loadMissions;
  final MissionStorage? missionStorage;
  final Widget Function(String level)? wordsBuilder;
  @override
  State<LearningHubPage> createState() => _LearningHubPageState();
}

class _LearningHubPageState extends State<LearningHubPage> {
  String level = 'A1';
  bool missions = false;
  int wordsRevision = 0;
  @override
  void initState() {
    super.initState();
    try {
      final preferred = AccountStore.current().get('CurrentLevel');
      if (contentLevels.contains(preferred)) level = preferred as String;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xfffaf8ff),
      appBar: AppBar(
          title: const Text('Learning library'),
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xfffaf8ff)),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 10, runSpacing: 8, children: [
                ChoiceChip(
                    avatar: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Words'),
                    selected: !missions,
                    onSelected: (_) => setState(() {
                          missions = false;
                          wordsRevision++;
                        })),
                ChoiceChip(
                    avatar: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Missions'),
                    selected: missions,
                    onSelected: (_) => setState(() => missions = true)),
              ]),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: contentLevels
                      .map((l) => ChoiceChip(
                          label: Text(l),
                          selected: l == level,
                          onSelected: (_) => setState(() => level = l)))
                      .toList()),
            ])),
        Expanded(
            child: missions
                ? MissionBoard(
                    level: level,
                    storage: widget.missionStorage,
                    load: widget.loadMissions)
                : widget.wordsBuilder?.call(level) ??
                    ContentLibraryPage(
                        key: ValueKey('words:$level:$wordsRevision'),
                        embedded: true,
                        initialLevel: level)),
      ]));
}

class MissionBoard extends StatefulWidget {
  const MissionBoard({super.key, required this.level, this.load, this.storage});
  final String level;
  final Future<List<Mission>> Function()? load;
  final MissionStorage? storage;
  @override
  State<MissionBoard> createState() => _MissionBoardState();
}

class _MissionBoardState extends State<MissionBoard> {
  late Future<List<Mission>> data;
  MissionStorage? storage;
  @override
  void initState() {
    super.initState();
    try {
      storage = widget.storage ?? AccountMissionStorage(AccountStore.current());
    } catch (_) {}
    _load();
  }

  void _load() {
    data = widget.load?.call() ??
        Future.wait([
          rootBundle.loadString('assets/missions_catalog_v1.json'),
          rootBundle.loadString('assets/missions_archive_v1.json'),
        ]).then((s) => [
              ...decodeMissions(s[0], preview: kDebugMode),
              ...decodeMissions(s[1], preview: kDebugMode, archive: true),
            ]);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Mission>>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Could not load missions.'),
            TextButton(
                onPressed: () => setState(_load), child: const Text('Retry'))
          ]));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final latest = <String, Mission>{};
        for (final m in snapshot.requireData) {
          if (latest[m.id] == null || latest[m.id]!.version < m.version)
            latest[m.id] = m;
        }
        final missions =
            latest.values.where((m) => m.level == widget.level).toList();
        return ListView(padding: const EdgeInsets.all(20), children: [
          Text('Use German in real life',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('A short conversation. A useful new skill.'),
          const SizedBox(height: 20),
          if (missions.isEmpty)
            Text(
                'Reviewed ${widget.level} missions are being prepared. You can still explore words for this level.'),
          ...missions.map((m) {
            Map<String, dynamic>? saved;
            try {
              saved = storage?.read(m.id);
            } catch (_) {}
            final old = snapshot.requireData
                .where((v) =>
                    v.id == m.id && v.version == saved?['contentVersion'])
                .firstOrNull;
            final completed =
                saved != null && saved['position'] == (old ?? m).steps.length;
            final expanded = old != null && old.version != m.version;
            final choiceUpgrade =
                old != null && canUpgradeMissionChoices(old, m);
            return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                    color: const Color(0xffeee2fb),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => MissionPage(
                                      mission: expanded &&
                                              !completed &&
                                              !choiceUpgrade
                                          ? old
                                          : m,
                                      previousVersion: expanded &&
                                              (completed || choiceUpgrade)
                                          ? old
                                          : null,
                                      storage: storage)));
                          if (mounted) setState(() {});
                        },
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.emoji,
                                      style: const TextStyle(fontSize: 44)),
                                  const SizedBox(height: 12),
                                  Text(m.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(m.objective),
                                  const SizedBox(height: 12),
                                  Text(
                                      '${m.level} · ${m.minutes} min · ${m.steps.length} steps'),
                                  if (m.status == 'draft')
                                    const Text(
                                        'Pilot preview · Review pending'),
                                  const SizedBox(height: 16),
                                  Row(children: [
                                    Icon(completed
                                        ? Icons.check_circle_outline
                                        : saved == null
                                            ? Icons.play_circle_outline
                                            : Icons.play_arrow),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(expanded && completed
                                            ? 'New conversation available'
                                            : completed
                                                ? 'Completed · See result & review goal'
                                                : saved == null
                                                    ? 'Begin mission'
                                                    : 'Continue mission'))
                                  ]),
                                ])))));
          }),
        ]);
      });
}
