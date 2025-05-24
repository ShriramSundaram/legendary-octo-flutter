import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:germanreminder/resultPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'germanQuizData.dart';

class germanBasicTest extends StatefulWidget {
  const germanBasicTest({Key? key}) : super(key: key);

  @override
  State<germanBasicTest> createState() => _germanBasicTestState();
}

class _germanBasicTestState extends State<germanBasicTest> {
  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedOption;
  int remainingTime = 400; // in Seconds
  late Timer _timer;
  String recommendedGermanLevel = 'A1';
  bool timeStarted = false;
  List<int> alreadyPresent = [];
  var ran = Random();
  String? motive = "Time's up!"; // Add a default value

  // Add loading state and quiz data list
  bool isLoading = true;
  List<GermanQuiz> quizData = [];

  @override
  void initState() {
    super.initState();
    // Load quiz data when widget initializes
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      quizData = await loadQuizData();
      quizData.shuffle(); // Shuffle questions every time
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading quiz data: $e');
      // Show error message to user
    }
  }

  void CheckGermanLevel() {
    // Set recommendedGermanLevel based on score for levels A1, A2, B1, B2, C1, C2
    double percent = score / quizData.length;
    if (percent < 0.2) {
      recommendedGermanLevel = 'A1';
    } else if (percent < 0.4) {
      recommendedGermanLevel = 'A2';
    } else if (percent < 0.6) {
      recommendedGermanLevel = 'B1';
    } else if (percent < 0.75) {
      recommendedGermanLevel = 'B2';
    } else if (percent < 0.9) {
      recommendedGermanLevel = 'C1';
    } else {
      recommendedGermanLevel = 'C2';
    }
    // You can add more logic or use motive if needed
  }

  Future<void> checkAnswer() async {
    if (selectedOption == quizData[currentQuestionIndex].CorrectOption) {
      setState(() {
        score++;
      });
    }

    if (currentQuestionIndex < quizData.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOption = null;
      });
    } else {
      _timer.cancel();
      await showResult();
      CheckGermanLevel();
    }
  }

  Future<void> showResult() async {
    int attempted = currentQuestionIndex + (selectedOption != null ? 1 : 0);
    int correct = score;
    int wrong = attempted - correct;
    int unanswered = quizData.length - attempted;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
            score, // correct
            quizData.length, // total
            recommendedGermanLevel,
            motive ?? "Time's up!",
            correct: correct,
            wrong: wrong < 0 ? 0 : wrong,
            unanswered: unanswered < 0 ? 0 : unanswered),
      ),
    );
  }

  // Rest of your methods remain unchanged...

  void StartTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        _timer.cancel();
        showResult();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while quiz data is loading
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('German BasicTest'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Format timer as minutes:seconds
    String timerText =
        '${remainingTime ~/ 60}:${(remainingTime % 60).toString().padLeft(2, '0')}';

    // Show quiz UI after data is loaded
    return Scaffold(
      appBar: AppBar(
        title: Text('German BasicTest'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Timer UI remains unchanged...
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: remainingTime < 30
                      ? Colors.red.shade100
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: remainingTime < 30 ? Colors.red : Colors.blue,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      color: remainingTime < 30 ? Colors.red : Colors.blue,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Time: $timerText',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: remainingTime < 30 ? Colors.red : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              // --- Statistics Row ---
              SizedBox(height: 15),
              _buildStatRow(),
              SizedBox(height: 20),
              Text('Pick the Exact meaning for the German Word',
                  style: GoogleFonts.openSans(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Container(
                width: 250,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  // Use quizData instead of QuizData
                  quizData[currentQuestionIndex].Questions,
                  textScaleFactor: 5.0,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 5.0,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20),
              Column(
                children: quizData[
                        currentQuestionIndex] // Changed from QuizData to quizData
                    .Options
                    .asMap()
                    .entries
                    .map((entry) => RadioListTile<int>(
                          title: Text(entry.value),
                          value: entry.key,
                          groupValue: selectedOption,
                          onChanged: timeStarted
                              ? (value) {
                                  setState(() {
                                    selectedOption = value!;
                                  });
                                }
                              : null, // This makes it disabled
                        ))
                    .toList(),
              ),
              ElevatedButton(
                onPressed: (timeStarted && selectedOption != null)
                    ? checkAnswer
                    : null,
                child: Text("Next"),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                width: 140,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    if (timeStarted == false) {
                      StartTimer();
                      timeStarted = true;
                    }
                  },
                  style: ButtonStyle(
                      backgroundColor: timeStarted
                          ? MaterialStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(MaterialState.pressed)) {
                                return Color.fromARGB(
                                    255, 91, 6, 238); // Color when pressed
                              }
                              return Color.fromARGB(
                                  255, 180, 143, 245); // Default color
                            })
                          : MaterialStateProperty.resolveWith<Color?>((states) {
                              return Color.fromARGB(255, 91, 6, 238);
                            })),
                  child: Text('Start',
                      style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 2.2,
                          color: Colors.black)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Add this helper widget to your class (outside build method)
  Widget _buildStatRow() {
    int attempted = currentQuestionIndex;
    int unanswered = quizData.length - attempted;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatItem(Icons.help_outline, Colors.blue, 'Unanswered',
              '${unanswered < 0 ? 0 : unanswered}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, Color color, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
