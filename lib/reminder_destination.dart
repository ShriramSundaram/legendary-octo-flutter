import 'package:flutter/material.dart';
import 'data/account_store.dart';
import 'data/reminder_models.dart';
import 'data/offline_vocabulary.dart';
import 'data/offline_vocabulary_loader.dart';
import 'pronunciation_button.dart';
import 'review_session_page.dart';

class ReminderDestination extends StatefulWidget {
  const ReminderDestination({super.key, required this.payload});
  final ReminderPayload payload;
  @override
  State<ReminderDestination> createState() => _ReminderDestinationState();
}

class _ReminderDestinationState extends State<ReminderDestination> {
  late final Future<OfflineVocabulary> vocabulary = loadOfflineVocabulary();
  bool revealed = false;
  @override
  Widget build(BuildContext context) {
    final uid = AccountStore.activeUid;
    if (uid == null || reminderOwner(uid) != widget.payload.owner)
      return const Scaffold(
          body: Center(
              child:
                  Text('Sign in to the account that created this reminder.')));
    if (widget.payload.itemId == null)
      return ReviewSessionPage(level: widget.payload.level);
    return Scaffold(
        appBar: AppBar(title: const Text('Your saved word')),
        body: FutureBuilder<OfflineVocabulary>(
            future: vocabulary,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              final found = snapshot.data?.words
                      .where((w) =>
                          w.id == widget.payload.itemId &&
                          w.level == widget.payload.level)
                      .toList() ??
                  [];
              return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (found.isEmpty)
                          const Text(
                              'This word is unavailable. You can still review this level.')
                        else
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(children: [
                                    Text(found.first.german,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium),
                                    PronunciationButton(
                                        text: found.first.german),
                                    if (revealed)
                                      Text(found.first.meaning,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge)
                                    else
                                      TextButton(
                                          onPressed: () =>
                                              setState(() => revealed = true),
                                          child: const Text('Reveal meaning')),
                                  ]))),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                            onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ReviewSessionPage(
                                        level: widget.payload.level))),
                            icon: const Icon(Icons.school),
                            label:
                                Text('Review ${widget.payload.level} words')),
                      ]));
            }));
  }
}
