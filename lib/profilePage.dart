import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:germanreminder/editProfilePage.dart';
import 'package:germanreminder/frontPage.dart';
import 'package:germanreminder/main.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

final user = FirebaseAuth.instance.currentUser;
String? localPath;

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController userNameEditor = TextEditingController();
  String? userName;

  // Initialize the object for Hive
  final hiveDatabase = Hive.box('LocalDatabase');

  void goToEditProfilePage(context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => EditProfilePage()));

  void goToHomePage(context) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MyHomePage(
            title: 'German Reminder',
          )));

  @override
  void initState() {
    if (hiveDatabase.containsKey('UserName')) {
      userName = hiveDatabase.get('UserName');
    } else {
      userName = '';
    }

    loadImage();
  }

  Future<void> deleteUserAccount() async {
    try {
      await FirebaseAuth.instance.currentUser!.delete();
      showDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                title: Text('Alert !!!!'),
                content: Text('Your Account is Deleted!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      goToFrontScreen(context);
                      // SettingUpUserDatabase();
                    },
                    child: Text('Close'),
                  )
                ],
              ));
    } on FirebaseAuthException catch (e) {
      showDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                title: Text('Alert !!!!'),
                content: Text(e.toString()),
                actions: [
                  TextButton(
                    onPressed: () {
                      goToFrontScreen(context);
                      // SettingUpUserDatabase();
                    },
                    child: Text('Close'),
                  )
                ],
              ));
    }
  }

  void goToFrontScreen(context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => FrontPage()));

  void loadImage() async {
    SharedPreferences imagePath = await SharedPreferences.getInstance();

    if (imagePath.containsKey('ImagePath')) {
      setState(() {
        localPath = imagePath.getString('ImagePath');
      });
    } else {
      setState(() {
        localPath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: Theme.of(context).textTheme.headline4),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
            },
            icon: Icon(isDark ? LineAwesomeIcons.moon : LineAwesomeIcons.sun),
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.only(left: 15, top: 20, right: 20),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: ListView(
            children: [
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
                        child: localPath != null
                            ? CircleAvatar(
                                backgroundImage: FileImage(File(localPath!)),
                                radius: 65,
                              )
                            : CircleAvatar(
                                backgroundImage:
                                    AssetImage('assets/app_logo.png'),
                                radius: 65,
                              ),
                      )),
                ]),
              ),
              SizedBox(
                height: 30,
              ),
              SizedBox(
                height: 20,
                child: Text('Full Name',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 12.0,
                        fontWeight: FontWeight.normal,
                        fontFamily: "OpenSans")),
              ),
              buildTextField(
                  'Full Name', userName != null ? userName! : '', false, false),
              SizedBox(
                height: 30,
              ),
              SizedBox(
                height: 20,
                child: Text('Verified Email Status',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 12.0,
                        fontWeight: FontWeight.normal,
                        fontFamily: "OpenSans")),
              ),
              buildTextField('user verified', user!.emailVerified.toString(),
                  false, false),
              SizedBox(
                height: 30,
              ),
              SizedBox(
                height: 20,
                child: Text('Email',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 12.0,
                        fontWeight: FontWeight.normal,
                        fontFamily: "OpenSans")),
              ),
              buildTextField('Mail Id', user!.email.toString(), false, false),
              Container(
                  width: 320,
                  height: 50,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16.0),
                  margin: EdgeInsets.symmetric(horizontal: 20.0),
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20)),
                  child: MaterialButton(
                      highlightElevation: 2.0,
                      splashColor: Colors.blue,
                      onPressed: () {
                        deleteUserAccount();
                        goToFrontScreen(context);
                      },
                      child: const Text(
                        "Delete Account",
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                      )))
            ],
          ),
        ),
      ),
      bottomSheet: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            width: 140,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(
                  width: 6, color: Color.fromARGB(255, 177, 151, 250)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: OutlinedButton(
              onPressed: () {
                goToHomePage(context);
              },
              child: Text('Back',
                  style: TextStyle(
                      fontSize: 16, letterSpacing: 2.2, color: Colors.black)),
            ),
          ),
          Container(
            width: 140,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(
                  width: 6, color: Color.fromARGB(255, 177, 151, 250)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: OutlinedButton(
              onPressed: () {
                goToEditProfilePage(context);
              },
              child: Text('Edit',
                  style: TextStyle(
                      fontSize: 16, letterSpacing: 2.2, color: Colors.black)),
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
        child: istextField
            ? TextField(
                obscureText: isPasswordTextField ? true : false,
                //controller: userNameEditor,
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
              )
            : Container(
                padding: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 250, 248, 250),
                    border: Border.symmetric(vertical: BorderSide.none),
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                child: Text(
                  placeHolder,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: "OpenSans"),
                )));
  }
}
