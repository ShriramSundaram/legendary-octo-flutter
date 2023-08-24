import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:germanreminder/profilePage.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String userName = '';

  File? _image;
  String? localPath;

  bool onSelectedLevelA = true;
  bool onSelectedLevelA2 = true;
  bool onSelectedLevelB1 = true;
  bool onSelectedLevelB2 = true;
  bool onSelectedLevelC1 = true;

  String? onSelectedLevel;

  TextEditingController userNameEditor = TextEditingController();
  // Initialize the object for Hive
  final hiveDatabase = Hive.box('LocalDatabase');
  // Write
  void writeUserName() {
    if (userNameEditor.text == null || userNameEditor.text == '') {
      if (!hiveDatabase.containsKey('UserName')) {
        hiveDatabase.put('UserName', '');
      }
    } else {
      hiveDatabase.put('UserName', userNameEditor.text);
    }
  }

  void getUserName() {
    if (hiveDatabase.containsKey('UserName')) {
      userName = hiveDatabase.get('UserName');
    }
  }

  void goToProfilePage(context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => ProfilePage()));

  Future imageUpload() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() => _image = File(image.path));
      saveImage(File(image.path));
    } on PlatformException catch (e) {
      print(" Failed to upload image : $e");
      showDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                title: Text('Alert !!!!'),
                content: Text(e.message.toString()),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Close'),
                  )
                ],
              ));
    }
  }

  void saveImage(File img) async {
    SharedPreferences saveImage = await SharedPreferences.getInstance();
    saveImage.setString('ImagePath', img.path);
  }

  void loadImage() async {
    SharedPreferences imagePath = await SharedPreferences.getInstance();

    if (imagePath.containsKey('ImagePath')) {
      setState(() {
        localPath = imagePath.getString('ImagePath');
        print("Entered!!!!" + localPath.toString());
      });
    } else {
      localPath = '';
    }
  }

  void writeGermanLevel() {
    if (onSelectedLevel == 'A') {
      hiveDatabase.put('CurrentLevel', 'A1');
    }
    if (onSelectedLevel == 'A2') {
      hiveDatabase.put('CurrentLevel', 'A2');
    }
    if (onSelectedLevel == 'B1') {
      hiveDatabase.put('CurrentLevel', 'B1');
    }
    if (onSelectedLevel == 'B2') {
      hiveDatabase.put('CurrentLevel', 'B2');
    }
    if (onSelectedLevel == 'C1') {
      hiveDatabase.put('CurrentLevel', 'C1');
    }
  }

  @override
  void initState() {
    loadImage();
    writeUserName();
    getUserName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          padding: EdgeInsets.only(left: 15, top: 20, right: 20),
          child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: ListView(children: [
                Center(
                  child: Stack(children: [
                    Container(
                        alignment: Alignment.center,
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          border: Border.all(width: 6, color: Colors.white),
                          borderRadius: BorderRadius.circular(80),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(80),
                          child: (_image != null)
                              ? CircleAvatar(
                                  backgroundImage: FileImage(_image!),
                                  radius: 65,
                                )
                              : (localPath != '' && localPath != null)
                                  ? CircleAvatar(
                                      backgroundImage:
                                          FileImage(File(localPath!)),
                                      radius: 65,
                                    )
                                  : CircleAvatar(
                                      backgroundImage:
                                          AssetImage('assets/app_logo.png'),
                                      radius: 65,
                                    ),
                        )),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: Colors.blue),
                        child: IconButton(
                          onPressed: () {
                            imageUpload();
                          },
                          icon: Icon(Icons.edit),
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ]),
                ),
                SizedBox(
                  height: 60,
                ),
                buildTextField(
                    'Full Name',
                    userName != '' ? userName : hiveDatabase.get('UserName'),
                    false,
                    true),
                SizedBox(
                  height: 45,
                ),
                SizedBox(
                  height: 25,
                  child: Text(
                    'Choose your German Level',
                    style: const TextStyle(
                        fontFamily: "OpenSans",
                        fontSize: 16.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Row(children: [
                  Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            width: 6,
                            color: onSelectedLevelA
                                ? Color.fromARGB(255, 130, 103, 204)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(80),
                      ),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(80),
                          child: InkWell(
                            onTap: onSelectedLevelA
                                ? () {
                                    setState(() {
                                      onSelectedLevelA = false;
                                      onSelectedLevelA2 = true;
                                      onSelectedLevelB1 = true;
                                      onSelectedLevelB2 = true;
                                      onSelectedLevelC1 = true;
                                      onSelectedLevel = "A";
                                    });
                                  }
                                : null,
                            splashColor: Colors.deepPurpleAccent,
                            child: CircleAvatar(
                              backgroundImage: AssetImage('assets/A1.png'),
                              radius: 25,
                            ),
                          ))),
                  SizedBox(
                    width: 8,
                  ),
                  Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            width: 6,
                            color: onSelectedLevelA2
                                ? Color.fromARGB(255, 130, 103, 204)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(80),
                      ),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(80),
                          child: InkWell(
                            onTap: onSelectedLevelA2
                                ? () {
                                    setState(() {
                                      onSelectedLevelA = true;
                                      onSelectedLevelA2 = false;
                                      onSelectedLevelB1 = true;
                                      onSelectedLevelB2 = true;
                                      onSelectedLevelC1 = true;
                                      onSelectedLevel = "A2";
                                    });
                                  }
                                : null,
                            splashColor: Colors.deepPurpleAccent,
                            child: CircleAvatar(
                              backgroundImage: AssetImage('assets/A2.png'),
                              radius: 25,
                            ),
                          ))),
                  SizedBox(
                    width: 8,
                  ),
                  Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            width: 6,
                            color: onSelectedLevelB1
                                ? Color.fromARGB(255, 130, 103, 204)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(80),
                      ),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(80),
                          child: InkWell(
                            onTap: onSelectedLevelB1
                                ? () {
                                    setState(() {
                                      onSelectedLevelA2 = true;
                                      onSelectedLevelA = true;
                                      onSelectedLevelB1 = false;
                                      onSelectedLevelB2 = true;
                                      onSelectedLevelC1 = true;
                                      onSelectedLevel = "B1";
                                    });
                                  }
                                : null,
                            splashColor: Colors.deepPurpleAccent,
                            child: CircleAvatar(
                              backgroundImage: AssetImage('assets/B1.png'),
                              radius: 25,
                            ),
                          ))),
                  SizedBox(
                    width: 8,
                  ),
                  Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            width: 6,
                            color: onSelectedLevelB2
                                ? Color.fromARGB(255, 130, 103, 204)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(80),
                      ),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(80),
                          child: InkWell(
                            onTap: onSelectedLevelB2
                                ? () {
                                    setState(() {
                                      onSelectedLevelA2 = true;
                                      onSelectedLevelA = true;
                                      onSelectedLevelB1 = true;
                                      onSelectedLevelB2 = false;
                                      onSelectedLevelC1 = true;
                                      onSelectedLevel = "B2";
                                    });
                                  }
                                : null,
                            splashColor: Colors.deepPurpleAccent,
                            child: CircleAvatar(
                              backgroundImage: AssetImage('assets/B2.png'),
                              radius: 25,
                            ),
                          ))),
                  SizedBox(
                    width: 8,
                  ),
                  Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            width: 6,
                            color: onSelectedLevelC1
                                ? Color.fromARGB(255, 130, 103, 204)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(80),
                      ),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(80),
                          child: InkWell(
                            onTap: onSelectedLevelC1
                                ? () {
                                    setState(() {
                                      onSelectedLevelA2 = true;
                                      onSelectedLevelA = true;
                                      onSelectedLevelB1 = true;
                                      onSelectedLevelB2 = true;
                                      onSelectedLevelC1 = false;
                                      onSelectedLevel = "C1";
                                    });
                                  }
                                : null,
                            splashColor: Colors.deepPurpleAccent,
                            child: CircleAvatar(
                              backgroundImage: AssetImage('assets/C1.png'),
                              radius: 25,
                            ),
                          )))
                ])
              ]))),
      bottomSheet: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            width: 140,
            height: 40,
            decoration: BoxDecoration(
                border: Border.all(
                    width: 6, color: Color.fromARGB(255, 177, 151, 250)),
                borderRadius: BorderRadius.circular(20)),
            child: OutlinedButton(
              onPressed: () {
                goToProfilePage(context);
              },
              child: Text('Cancel',
                  style: TextStyle(
                      fontSize: 14, letterSpacing: 2.2, color: Colors.black)),
            ),
          ),
          Container(
            width: 140,
            height: 40,
            decoration: BoxDecoration(
                border: Border.all(
                    width: 6, color: Color.fromARGB(255, 177, 151, 250)),
                borderRadius: BorderRadius.circular(20)),
            child: OutlinedButton(
              onPressed: () {
                writeUserName();
                goToProfilePage(context);
                writeGermanLevel();
                if (_image != null) {
                  saveImage(_image!);
                }
              },
              child: Text('Save',
                  style: TextStyle(
                      fontSize: 14, letterSpacing: 2.2, color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(String labelText, String placeHolder,
      bool isPasswordTextField, bool istextField) {
    return Padding(
        padding: EdgeInsets.only(bottom: 30),
        child: TextField(
          obscureText: isPasswordTextField ? true : false,
          controller: userNameEditor,
          decoration: InputDecoration(
              contentPadding: EdgeInsets.only(bottom: 5),
              labelText: labelText,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintText: placeHolder,
              hintStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: "OpenSans")),
        ));
  }
}
