import 'package:flutter/material.dart';

class VocabularyEntry {
  final String id, text;
  final bool preview;
  const VocabularyEntry(this.id, this.text, {this.preview = false});
}

class VocabularySearchField extends StatelessWidget {
  const VocabularySearchField(
      {super.key, required this.onChanged, this.controller});
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(Icons.search),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2)))));
}

/// Both the offline dictionary and My words use this exact browsing surface.
class VocabularyCards extends StatelessWidget {
  const VocabularyCards(
      {super.key,
      required this.entries,
      required this.selectedId,
      required this.onSelect,
      required this.onSpeak,
      this.emptyMessage = 'No words found.'});
  final List<VocabularyEntry> entries;
  final String? selectedId;
  final ValueChanged<String> onSelect, onSpeak;
  final String emptyMessage;
  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty)
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24), child: Text(emptyMessage)));
    return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = entries[index], selected = entry.id == selectedId;
          return Card(
              elevation: selected ? 4 : 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: selected ? Colors.blue.shade50 : null,
              child: ListTile(
                  selected: selected,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Icon(Icons.text_fields,
                      color: selected ? Colors.blue : Colors.black54),
                  title: Text(entry.text,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal)),
                  subtitle: entry.preview
                      ? const Text('Preview · Review pending')
                      : null,
                  onTap: () => onSelect(entry.id),
                  trailing: IconButton(
                      tooltip: 'Speak',
                      onPressed: () => onSpeak(entry.text),
                      icon: const Icon(Icons.volume_up),
                      color: Colors.blue)));
        });
  }
}
