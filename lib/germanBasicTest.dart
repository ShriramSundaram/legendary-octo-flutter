import 'package:flutter/material.dart';
import 'germanQuizData.dart';
import 'practice_page.dart';

class germanBasicTest extends StatefulWidget {
  const germanBasicTest({super.key, this.loadQuestions});
  final Future<List<GermanQuiz>> Function()? loadQuestions;
  @override
  State<germanBasicTest> createState() => _germanBasicTestState();
}

class _germanBasicTestState extends State<germanBasicTest> {
  late Future<List<GermanQuiz>> questions;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    questions =
        Future.sync(() => widget.loadQuestions?.call() ?? loadQuizData());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Quick vocabulary check')),
      body: FutureBuilder<List<GermanQuiz>>(
          future: questions,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError || snapshot.requireData.isEmpty) {
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(snapshot.hasError
                    ? 'Quiz content could not be loaded.'
                    : 'Reviewed quiz content is being prepared.'),
                if (snapshot.hasError)
                  TextButton(
                      onPressed: () => setState(_load),
                      child: const Text('Retry')),
              ]));
            }
            final cards = buildQuickVocabularyCheck(snapshot.requireData);
            return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Find a place to start',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const Text(
                          '12 meaning-choice questions: 3 each from A1, A2, B1 and B2. See which sampled vocabulary needs practice.'),
                      const SizedBox(height: 16),
                      const Text(
                          'This is a small vocabulary snapshot. It does not assess grammar, speaking or your overall German level. C1/C2 are not assessed.'),
                      if (cards.isEmpty)
                        const Text(
                            'More reviewed questions are needed before this check is available.'),
                      FilledButton(
                          onPressed: cards.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => PracticePage(
                                              cards: cards,
                                              level: 'A1–B2',
                                              quickCheck: true,
                                              limit:
                                                  const Duration(minutes: 4))));
                                },
                          child: const Text('Open quick check')),
                    ]));
          }));
}
