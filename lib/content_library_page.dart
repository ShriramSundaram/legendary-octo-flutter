import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'data/learning_catalog_loader.dart';
import 'data/content_catalog.dart';
import 'data/review_controller.dart';
import 'data/review_store.dart';
import 'data/practice_speech.dart';
import 'databaseFirebase.dart';
import 'pronunciation_button.dart';
import 'review_session_page.dart';
import 'topic_test_page.dart';

class ContentLibraryPage extends StatefulWidget {
  const ContentLibraryPage(
      {super.key,
      this.previewDrafts = true,
      this.loadCatalog,
      this.reviewStorage,
      this.speech,
      this.embedded = false,
      this.initialLevel});
  final bool previewDrafts, embedded;
  final String? initialLevel;
  final Future<ContentCatalog> Function()? loadCatalog;
  final ReviewStorage? reviewStorage;
  final PracticeSpeech? speech;
  @override
  State<ContentLibraryPage> createState() => _ContentLibraryPageState();
}

class _ContentLibraryPageState extends State<ContentLibraryPage> {
  late Future<ContentCatalog> _catalog;
  final search = TextEditingController();
  ReviewStorage? storage;
  ReviewController? review;
  String level = 'A1', query = '';
  String? topic;
  bool get preview => kDebugMode && widget.previewDrafts;
  @override
  void initState() {
    super.initState();
    if (contentLevels.contains(widget.initialLevel))
      level = widget.initialLevel!;
    try {
      storage = widget.reviewStorage ?? AccountReviewStorage.current();
      if (widget.initialLevel == null && storage is AccountReviewStorage) {
        final preferred =
            (storage as AccountReviewStorage).account.get('CurrentLevel');
        if (contentLevels.contains(preferred)) level = preferred as String;
      }
    } catch (_) {}
    _load();
  }

  @override
  void didUpdateWidget(covariant ContentLibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLevel != widget.initialLevel &&
        contentLevels.contains(widget.initialLevel)) {
      level = widget.initialLevel!;
      topic = null;
      query = '';
      search.clear();
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _read(ContentCatalog catalog) {
    try {
      review = storage == null ? null : ReviewController(catalog, storage!);
    } catch (_) {
      review = null;
    }
  }

  void _load() {
    _catalog = (widget.loadCatalog?.call() ??
            loadLearningCatalog(includeDrafts: preview))
        .then((c) {
      _read(c);
      return c;
    });
  }

  Future<void> _open(ContentCatalog catalog, bool test) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => test
                ? TopicTestPage(
                    level: level,
                    topic: topic,
                    loadCatalog: () async => catalog)
                : ReviewSessionPage(
                    level: level,
                    topic: topic,
                    storage: storage,
                    speech: widget.speech,
                    loadCatalog: () async => catalog)));
    if (mounted) setState(() => _read(catalog));
  }

  String _emoji(String text) {
    final t = text.toLowerCase();
    if (t.contains('food')) return '🍓';
    if (t.contains('travel')) return '🧳';
    if (t.contains('home')) return '🏡';
    if (t.contains('greet')) return '👋';
    if (t.contains('work')) return '💼';
    if (t.contains('health')) return '🌿';
    if (t.contains('time') || t.contains('daily')) return '☀️';
    if (t.contains('shop')) return '🛍️';
    if (t.contains('family')) return '🧡';
    return '✨';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xfffaf8ff),
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Learning library'),
              backgroundColor: const Color(0xfffaf8ff)),
      bottomNavigationBar: FutureBuilder<ContentCatalog>(
          future: _catalog,
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox();
            final c = snap.requireData,
                available = c.published(level, topic: topic).isNotEmpty;
            return Material(
                color: const Color(0xfffaf8ff),
                elevation: 4,
                child: SafeArea(
                    top: false,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(level + ' · ' + (topic ?? 'All topics'),
                                  textAlign: TextAlign.center),
                              FilledButton.icon(
                                  onPressed:
                                      available ? () => _open(c, false) : null,
                                  icon: const Icon(Icons.school_outlined),
                                  label: Text(review?.canResume == true
                                      ? 'Continue saved session'
                                      : 'Start practice')),
                              TextButton.icon(
                                  onPressed:
                                      available ? () => _open(c, true) : null,
                                  icon: const Icon(Icons.headphones_outlined),
                                  label: const Text('Start Test'))
                            ]))));
          }),
      body: FutureBuilder<ContentCatalog>(
          future: _catalog,
          builder: (context, snap) {
            if (snap.hasError)
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Could not load the learning library.'),
                TextButton(
                    onPressed: () => setState(_load),
                    child: const Text('Retry'))
              ]));
            if (!snap.hasData)
              return const Center(child: CircularProgressIndicator());
            final c = snap.requireData, theme = Theme.of(context);
            final all = c.browse(level, includeDrafts: preview);
            final topics = all.map((w) => w.item.topic).toSet().toList()
              ..sort();
            final words = c
                .browse(level, topic: topic, includeDrafts: preview)
                .where((w) =>
                    query.isEmpty ||
                    (w.item.article + ' ' + w.item.lemma + ' ' + w.item.meaning)
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                .toList();
            return CustomScrollView(
                key: const PageStorageKey('learning-library'),
                slivers: [
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OutlinedButton.icon(
                                    onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => ViewGenericDatabase(
                                                GermanLevel: level == 'A1'
                                                    ? 'GenericCollections'
                                                    : 'GenericCollections$level'))),
                                    icon: const Icon(Icons.menu_book_outlined),
                                    label: const Text(
                                        'Browse all offline vocabulary')),
                                const SizedBox(height: 16),
                                if (!widget.embedded) ...[
                                  Text('Your level, your pace',
                                      style: theme.textTheme.titleLarge),
                                  const SizedBox(height: 12),
                                  Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: contentLevels
                                          .map((l) => ChoiceChip(
                                              label: Text('$l (' +
                                                  c
                                                      .browse(l,
                                                          includeDrafts:
                                                              preview)
                                                      .length
                                                      .toString() +
                                                  ' words)'),
                                              selected: l == level,
                                              onSelected: (_) => setState(() {
                                                    level = l;
                                                    topic = null;
                                                    query = '';
                                                    search.clear();
                                                  })))
                                          .toList())
                                ],
                                Text(
                                    all.length.toString() +
                                        ' words · Offline starter packs, not complete level coverage',
                                    style: theme.textTheme.bodySmall),
                                if (all.isEmpty)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      child: Text(
                                          'Reviewed $level content is being prepared. Your existing vocabulary is still available.')),
                                if (preview &&
                                    c.words.any((w) =>
                                        w.item.editorialStatus == 'draft'))
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                          'Vocabulary preview • Review pending\nMeanings and level tags are provisional.')),
                                if (topics.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text('Explore a topic',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: ChoiceChip(
                                          label: const Text('All topics'),
                                          selected: topic == null,
                                          onSelected: (_) =>
                                              setState(() => topic = null))),
                                  const SizedBox(height: 8),
                                  LayoutBuilder(builder: (context, box) {
                                    final wide = box.maxWidth >= 560 &&
                                        MediaQuery.textScalerOf(context)
                                                .scale(1) <
                                            1.6;
                                    return Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: topics.map((t) {
                                          final entries =
                                              c.published(level, topic: t);
                                          final seen = entries
                                              .where((w) =>
                                                  review?.states
                                                      .containsKey(w.item.id) ==
                                                  true)
                                              .length;
                                          final due =
                                              review?.dueCount(level, t) ?? 0;
                                          final selected = t == topic;
                                          return SizedBox(
                                              width: wide
                                                  ? (box.maxWidth - 12) / 2
                                                  : box.maxWidth,
                                              child: Semantics(
                                                  selected: selected,
                                                  child: Card(
                                                      color: selected
                                                          ? const Color(
                                                              0xffe9defa)
                                                          : Colors.white,
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  20),
                                                          side: BorderSide(
                                                              color: selected
                                                                  ? const Color(
                                                                      0xff8c65c6)
                                                                  : const Color(
                                                                      0xffe9e2f1))),
                                                      child: InkWell(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  20),
                                                          onTap: () => setState(
                                                              () => topic =
                                                                  selected
                                                                      ? null
                                                                      : t),
                                                          child: Padding(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                      18),
                                                              child: Row(
                                                                  children: [
                                                                    ExcludeSemantics(
                                                                        child: Text(
                                                                            _emoji(
                                                                                t),
                                                                            style:
                                                                                const TextStyle(fontSize: 28))),
                                                                    const SizedBox(
                                                                        width:
                                                                            12),
                                                                    Expanded(
                                                                        child: Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                          Text(
                                                                              t,
                                                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                                                          Text(entries.length.toString() +
                                                                              ' words · $seen practised'),
                                                                          if (due >
                                                                              0)
                                                                            Text('$due ready to revisit')
                                                                        ]))
                                                                  ]))))));
                                        }).toList());
                                  })
                                ],
                                const SizedBox(height: 20),
                                TextField(
                                    controller: search,
                                    onChanged: (s) =>
                                        setState(() => query = s.trim()),
                                    decoration: InputDecoration(
                                        labelText: 'Search German or English',
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon: query.isEmpty
                                            ? null
                                            : IconButton(
                                                tooltip: 'Clear search',
                                                icon: const Icon(Icons.close),
                                                onPressed: () => setState(() {
                                                      query = '';
                                                      search.clear();
                                                    })),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(18)))),
                                const SizedBox(height: 8),
                                Text(words.length == 1
                                    ? '1 word shown'
                                    : words.length.toString() + ' words shown'),
                              ]))),
                  if (words.isEmpty && all.isNotEmpty)
                    const SliverToBoxAdapter(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                                'No words match your search. Try another word or choose All topics.'))),
                  SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                    final word = words[index], item = word.item;
                    return Card(
                        color: Colors.white,
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        child: ExpansionTile(
                            key: PageStorageKey(
                                item.id + ':' + (topic ?? 'all') + ':$level'),
                            title: Text(
                                (item.article + ' ' + item.lemma).trim(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle:
                                const Text('Tap for meaning and pronunciation'),
                            childrenPadding: const EdgeInsets.all(20),
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              if (item.editorialStatus == 'draft')
                                const Text('Draft • review pending'),
                              Text(item.meaning,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                      color: const Color(0xff67459d))),
                              const SizedBox(height: 12),
                              Text(item.example),
                              Text(word.exampleTranslation),
                              if (word.partOfSpeech == 'noun')
                                Text('Plural: ' + item.plural),
                              if (word.usageNotes.isNotEmpty)
                                Text(word.usageNotes),
                              const SizedBox(height: 12),
                              PronunciationButton(
                                  key: ValueKey('audio:' + item.id),
                                  text:
                                      (item.article + ' ' + item.lemma).trim(),
                                  speech: widget.speech)
                            ]));
                  }, childCount: words.length)),
                ]);
          }));
}
