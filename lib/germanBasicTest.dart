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
  int remainingTime = 200; // in Seconds
  late Timer _timer;
  String recommendedGermanLevel = 'A1';
  String? motive;
  bool timeStarted = false;
  List<int> alreadyPresent = [];
  var ran = Random();

  void checkAnswer() {
    if (selectedOption == QuizData[currentQuestionIndex].CorrectOption) {
      setState(() {
        score++;
      });
    }

    if (currentQuestionIndex < QuizData.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOption = null;
      });
    } else {
      _timer.cancel();
      showResult();
      CheckGermanLevel();
    }
  }

  void showResult() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
            score, QuizData.length, recommendedGermanLevel, motive!),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  void StartTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          _timer.cancel();
          showResult();
          CheckGermanLevel();
        }
      });
    });
  }

  void CheckGermanLevel() {
    setState(() {
      if (score <= 10) {
        recommendedGermanLevel = 'A1';
        motive = "You definitely tried your best! Let"
            "'"
            "s start with your beginner journey.. ";
      }
      if (score > 10 && score <= 25) {
        recommendedGermanLevel = 'A2';
        motive = "That shows your enthusiasm to learn!! Let"
            "'"
            "s build your foundation stronger..";
      }
      if (score > 25 && score <= 30) {
        recommendedGermanLevel = 'B1';
        motive = "This is quite an accomplishment! Let"
            "'"
            "s continue your journey into the intermediate level..";
      }
      if (score > 30 && score <= 35) {
        recommendedGermanLevel = 'B2';
        motive = "That"
            "'"
            "s a noteworthy & promising effort; Just a few more steps to reach..";
      }
      if (score > 35 && score <= 40) {
        recommendedGermanLevel = 'C1';
        motive = "You"
            "'"
            "re right on target! a few hours of effort will make you an expert";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'German BasicTest',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 20,
              ),
              Text('Time Left',
                  style: GoogleFonts.roboto(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 10,
              ),
              Container(
                width: 80,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                    //color: Color.fromARGB(255, 147, 13, 145),
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.all(Radius.circular(30))),
                child: Text(
                  remainingTime.toString(),
                  textScaleFactor: 5.0,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 5.0,
                      fontWeight: FontWeight.bold,
                      backgroundColor: remainingTime < 10 ? Colors.red : null),
                ),
              ),
              SizedBox(
                height: 75,
              ),
              Text('Pick the Exact meaning for the German Word',
                  style: GoogleFonts.openSans(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 20,
              ),
              Container(
                width: 250,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  QuizData[currentQuestionIndex].Questions,
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
                children: QuizData[currentQuestionIndex]
                    .Options
                    .asMap()
                    .entries
                    .map((entry) => RadioListTile<int>(
                          title: Text(entry.value),
                          value: entry.key,
                          groupValue: selectedOption,
                          onChanged: (value) {
                            setState(() {
                              selectedOption = value!;
                            });
                          },
                        ))
                    .toList(),
              ),
              ElevatedButton(
                onPressed: selectedOption != null ? checkAnswer : null,
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
}
