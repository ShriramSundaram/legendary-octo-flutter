import 'package:flutter/material.dart';

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
