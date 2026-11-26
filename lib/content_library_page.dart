import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/content_catalog.dart';
import 'databaseFirebase.dart';
import 'review_session_page.dart';
import 'topic_test_page.dart';

class ContentLibraryPage extends StatefulWidget {
  const ContentLibraryPage(
      {super.key, this.previewDrafts = true, this.loadCatalog});
  final bool previewDrafts;
  final Future<ContentCatalog> Function()? loadCatalog;
  @override
  State<ContentLibraryPage> createState() => _ContentLibraryPageState();
}

class _ContentLibraryPageState extends State<ContentLibraryPage> {
  late Future<ContentCatalog> _catalog;
  String _level = 'A1';
  String? _topic;
  // A runtime argument can never expose unreviewed words in a release build.
  bool get _preview => kDebugMode && widget.previewDrafts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _catalog = widget.loadCatalog?.call() ??
        rootBundle
            .loadString('assets/content_catalog_v1.json')
            .then(ContentCatalog.decode);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Learning library')),
        body: FutureBuilder<ContentCatalog>(
            future: _catalog,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Could not load the learning library.'),
                  TextButton(
                      onPressed: () => setState(_load),
                      child: const Text('Retry')),
                ]));
              }
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final catalog = snapshot.requireData;
              final levelWords =
                  catalog.browse(_level, includeDrafts: _preview);
              final topics = levelWords
                  .map((word) => word.item.topic)
                  .toSet()
                  .toList()
                ..sort();
              final words = catalog.browse(_level,
                  topic: _topic, includeDrafts: _preview);
              final theme = Theme.of(context);
              return CustomScrollView(slivers: [
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Find your next word',
                                  style: theme.textTheme.headlineSmall),
                              const SizedBox(height: 8),
                              const Text(
                                  'Choose your level, then explore a topic. Available offline.'),
                              const SizedBox(height: 8),
                              const Text(
                                  'Start practice: recall words and hear pronunciation. Start Test: check meaning recognition and listening.'),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                  onPressed: catalog
                                          .published(_level, topic: _topic)
                                          .isEmpty
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) => TopicTestPage(
                                                  level: _level,
                                                  topic: _topic,
                                                  loadCatalog:
                                                      widget.loadCatalog))),
                                  icon: const Icon(Icons.auto_stories),
                                  label: const Text('Start Test')),
                              FilledButton.icon(
                                  onPressed: catalog
                                          .published(_level, topic: _topic)
                                          .isEmpty
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) => ReviewSessionPage(
                                                  level: _level,
                                                  topic: _topic,
                                                  loadCatalog:
                                                      widget.loadCatalog))),
                                  icon: const Icon(Icons.school),
                                  label: const Text('Start practice')),
                              TextButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => ViewGenericDatabase(
                                              GermanLevel: _level == 'A1'
                                                  ? 'GenericCollections'
                                                  : 'GenericCollections$_level'))),
                                  icon: const Icon(Icons.search),
                                  label: const Text(
                                      'Browse all offline vocabulary')),
                              if (_preview &&
                                  catalog.words.any((word) =>
                                      word.item.editorialStatus == 'draft'))
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme.secondaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Text(
                                            'Vocabulary preview • Review pending\nMeanings and level tags are provisional.',
                                            style: TextStyle(
                                                color: theme.colorScheme
                                                    .onSecondaryContainer)))),
                              const SizedBox(height: 8),
                              Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: contentLevels
                                      .map((level) => ChoiceChip(
                                            label: Text(
                                                '$level (${catalog.browse(level, includeDrafts: _preview).length} words)'),
                                            selected: _level == level,
                                            onSelected: (_) => setState(() {
                                              _level = level;
                                              _topic = null;
                                            }),
                                          ))
                                      .toList()),
                              const SizedBox(height: 12),
                              Text(
                                  '${levelWords.length} words • Offline starter packs, not complete level coverage'),
                              if (topics.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(spacing: 8, runSpacing: 4, children: [
                                  ChoiceChip(
                                      label: const Text('All topics'),
                                      selected: _topic == null,
                                      onSelected: (_) =>
                                          setState(() => _topic = null)),
                                  ...topics.map((topic) => ChoiceChip(
                                      label: Text(topic),
                                      selected: _topic == topic,
                                      onSelected: (_) =>
                                          setState(() => _topic = topic))),
                                ]),
                                const SizedBox(height: 8),
                                Text('${words.length} words shown',
                                    style: theme.textTheme.bodySmall),
                              ],
                            ]))),
                if (words.isEmpty)
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                              'Reviewed $_level content is being prepared. Your existing vocabulary is still available.')))
                else
                  SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                    final word = words[index];
                    final item = word.item;
                    return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: ExpansionTile(
                          key: ValueKey('${item.id}:${_topic ?? 'all'}'),
                          title: Text('${item.article} ${item.lemma}'.trim()),
                          subtitle: Text(item.meaning),
                          childrenPadding: const EdgeInsets.all(16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.editorialStatus == 'draft')
                              const Text('Draft • review pending'),
                            if (word.partOfSpeech == 'noun')
                              Text('Plural: ${item.plural}'),
                            const SizedBox(height: 8),
                            Text(item.example,
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(word.exampleTranslation),
                            if (word.usageNotes.isNotEmpty)
                              Text(word.usageNotes),
                          ],
                        ));
                  }, childCount: words.length)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ]);
            }),
      );
}
