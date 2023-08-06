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
                saveImage(_image!);
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
