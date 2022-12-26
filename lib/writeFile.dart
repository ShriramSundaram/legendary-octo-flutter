import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FileUtils {
  Future<String> get getFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get getFile async {
    final path = await getFilePath;
    print("Path:: " + path);
    return File('$path/GermanWords.txt');
  }

  Future<File> saveToFile(String data) async {
    final file = await getFile;
    return file.writeAsString('\n$data', mode: FileMode.append);
  }

  Future<List<String>> readDataFromFile() async {
    try {
      final file = await getFile;
      List<String> fileContents = await file.readAsLines();
      return fileContents;
    } catch (e) {
      return ["Couldn't Read the File"];
    }
  }
}

/*
Future writeFile(String data) async {
  String fileName = "GermanWords.txt";
  Directory tempDir = await getApplicationDocumentsDirectory();
  print(tempDir.path + fileName);
  final File file = File("${tempDir.path}/$fileName");
  //File file = File('assets/GermanWords.txt');
  // ignore: avoid_pr.int
  await file.writeAsString('\n$data', mode: FileMode.append);
}*/



/*
readDataFromFile() async {
  try {
    String fileName = "GermanWords.txt";
    Directory tempDir = await getApplicationDocumentsDirectory();
    print(tempDir.path + fileName);
    final File file = File("${tempDir.path}/$fileName");

    String fileContents = await file.readAsString();
    return fileContents;
  } catch (e) {
    return "Couldn't Read the File";
  }
}*/
