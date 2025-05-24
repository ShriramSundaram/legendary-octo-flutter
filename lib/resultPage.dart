import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final String recommendedGermanLevel;
  final String motivation;
  final int correct;
  final int wrong;
  final int unanswered;

  ResultScreen(this.score, this.totalQuestions, this.recommendedGermanLevel,
      this.motivation,
      {this.correct = 0, this.wrong = 0, this.unanswered = 0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quiz Results")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Your Score: $score / $totalQuestions",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "Correct: $correct",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.green,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              "Wrong: $wrong",
              style: TextStyle(
                  fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
            ),
            Text(
              "Unanswered: $unanswered",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 40,
            ),
            Text(
              "Your recommended level of German",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 20,
            ),
            CircleAvatar(
              backgroundColor: Color.fromARGB(255, 162, 124, 227),
              radius: 45,
              child: Text(
                recommendedGermanLevel,
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 75, 14, 179)),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              motivation,
              style: TextStyle(
                  fontSize: 20,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.normal,
                  color: Color.fromARGB(255, 88, 19, 179)),
            ),
            SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Navigate back to quiz
              },
              child: Text("Retake Test",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                      color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
