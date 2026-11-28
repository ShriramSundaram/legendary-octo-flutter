import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/content_catalog.dart';
import 'data/quiz_catalog.dart';
import 'data/topic_test_builder.dart';
import 'data/practice_session.dart';
import 'practice_page.dart';

class TopicTestPage extends StatefulWidget {
  const TopicTestPage(
      {super.key, required this.level, this.topic, this.loadCatalog});
  final String level;
  final String? topic;
  final Future<ContentCatalog> Function()? loadCatalog;
  @override
  State<TopicTestPage> createState() => _TopicTestPageState();
}

class _TopicTestPageState extends State<TopicTestPage> {
  late Future<List<PracticeCard>> lesson;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    lesson = _build();
  }

  Future<List<PracticeCard>> _build() async {
    final content = await (widget.loadCatalog?.call() ??
        rootBundle
            .loadString('assets/content_catalog_v1.json')
            .then(ContentCatalog.decode));
    final quizzes = QuizCatalog.decode(
        await rootBundle.loadString('assets/quiz_catalog_v1.json'), content);
    return buildTopicTest(content, quizzes, widget.level, topic: widget.topic);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PracticeCard>>(
      future: lesson,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.requireData.isNotEmpty) {
          return PracticePage(
              cards: snapshot.requireData,
              level: widget.level,
              topic: widget.topic);
        }
        return Scaffold(
            appBar: AppBar(title: const Text('Topic test')),
            body: Center(
                child: snapshot.connectionState != ConnectionState.done
                    ? const CircularProgressIndicator()
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(snapshot.hasError
                            ? 'Test content could not be loaded.'
                            : 'No reviewed test questions for this level/topic yet. Choose another selection, or use Start practice for recall and pronunciation.'),
                        if (snapshot.hasError)
                          TextButton(
                              onPressed: () => setState(_load),
                              child: const Text('Retry')),
                      ])));
      });
}
