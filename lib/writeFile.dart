import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class FileUtils {
  List<String> A2 = [
    // TODO ADD words Automatically
  ];

  // Gets the file path and performs file operations
  void getFilePath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String path = directory.path;
      debugPrint("Path: $path");
    } catch (e) {
      debugPrint("Error getting path: $e");
    }
  }

  // Save data to file
  void saveToFile(String data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/GermanWords.txt');
      await file.writeAsString('\n$data', mode: FileMode.append);
      debugPrint("Data saved successfully");
    } catch (e) {
      debugPrint('Error saving to file: $e');
    }
  }

  // Read data from file and return contents via callback
  void readDataFromFile(Function(List<String>) onComplete) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/GermanWords.txt');
      final List<String> fileContents = await file.readAsLines();
      debugPrint("Read ${fileContents.length} lines from file");
      onComplete(fileContents);
    } catch (e) {
      debugPrint('Error reading from file: $e');
      onComplete(["Couldn't Read the File"]);
    }
  }
}

// Alternative implementation
/*
void writeFile(String data) async {
  String fileName = "GermanWords.txt";
  Directory tempDir = await getApplicationDocumentsDirectory();
  print("${tempDir.path}/$fileName");
  final File file = File("${tempDir.path}/$fileName");
  //File file = File('assets/GermanWords.txt');
  await file.writeAsString('\n$data', mode: FileMode.append);
}
*/

// Alternative implementation for reading as a string
/*
Future<String> readDataFromFile() async {
  try {
    String fileName = "GermanWords.txt";
    Directory tempDir = await getApplicationDocumentsDirectory();
    print("${tempDir.path}/$fileName");
    final File file = File("${tempDir.path}/$fileName");

    String fileContents = await file.readAsString();
    return fileContents;
  } catch (e) {
    return "Couldn't Read the File";
  }
}
*/
