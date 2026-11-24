import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';

class GermanQuiz {
  final String Questions;
  final List<String> Options;
  final int CorrectOption;

  GermanQuiz(this.Questions, this.Options, this.CorrectOption);

  // Add a factory constructor to create from JSON
  factory GermanQuiz.fromJson(Map<String, dynamic> json) {
    return GermanQuiz(
      json['question'],
      List<String>.from(json['options']),
      json['correctOption'],
    );
  }
}

// This list will store quiz data
List<GermanQuiz> QuizData = [];

// Load quiz data from JSON file
dynamic loadQuizData() async {
  try {
    // Load JSON string from asset
    final jsonString = await rootBundle.loadString('assets/quiz_data.json');

    // Decode JSON
    final jsonData = json.decode(jsonString) as List;

    // Convert to GermanQuiz objects
    final quizList = jsonData.map((item) => GermanQuiz.fromJson(item)).toList();

    // Update global list for backward compatibility
    QuizData = quizList;

    // Return the list
    return quizList;
  } catch (e) {
    debugPrint('Error loading quiz data: $e');
    return [];
  }
}
