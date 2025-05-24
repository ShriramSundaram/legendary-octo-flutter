import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

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

// This function loads quiz data from the JSON file
Future<List<GermanQuiz>> loadQuizData() async {
  final jsonString = await rootBundle.loadString('assets/quiz_data.json');
  final jsonData = json.decode(jsonString) as List;
  return jsonData.map((item) => GermanQuiz.fromJson(item)).toList();
}

// Keep this for backward compatibility, but mark as deprecated
@Deprecated('Use loadQuizData() instead')
List<GermanQuiz> QuizData = [];
