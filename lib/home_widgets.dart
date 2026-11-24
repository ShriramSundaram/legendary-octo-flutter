import 'package:flutter/material.dart';

class ReminderTimeSelector extends StatelessWidget {
  const ReminderTimeSelector({
    super.key,
    required this.values,
    required this.items,
    required this.onChanged,
    required this.onStart,
  });

  final List<int?> values;
  final List<List<int>> items;
  final List<ValueChanged<int?>> onChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFAF86F6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(18) > 27;
        final stackFields = constraints.maxWidth < 240 || largeText;
        final separateAlarm = constraints.maxWidth < 320 || stackFields;
        final fields = List<Widget>.generate(3, (index) {
          final label = ['HH', 'MM', 'SS'][index];
          return DropdownButton<int>(
            isExpanded: true,
            value: values[index],
            borderRadius: BorderRadius.circular(20),
            dropdownColor: Colors.blueAccent,
            hint: Text(label),
            style: const TextStyle(fontSize: 18, color: Colors.black),
            items: items[index]
                .map((value) => DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString().padLeft(2, '0')),
                    ))
                .toList(),
            onChanged: onChanged[index],
          );
        });
        final alarm = IconButton(
          tooltip: 'Start reminder',
          onPressed: onStart,
          icon: const Icon(Icons.access_alarm,
              size: 30, color: Colors.blueAccent),
        );
        final fieldRow = Row(children: [
          for (var index = 0; index < fields.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(child: fields[index]),
          ],
          if (!separateAlarm) ...[const SizedBox(width: 8), alarm],
        ]);
        if (!separateAlarm) return fieldRow;
        return Column(children: [
          if (stackFields) ...fields else fieldRow,
          alarm,
        ]);
      }),
    );
  }
}

class HomeWordCard extends StatelessWidget {
  const HomeWordCard({super.key, required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 150),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFAF86F6),
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            spreadRadius: 5,
            blurRadius: 20,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        word,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class HomeWordInput extends StatelessWidget {
  const HomeWordInput({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        hintText: 'Add New Word',
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
      ),
      style: const TextStyle(
          fontFamily: 'OpenSans',
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.bold),
    );
  }
}
