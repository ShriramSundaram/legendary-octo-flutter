import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:germanreminder/frontPage.dart';
import 'package:germanreminder/main.dart';
import 'package:germanreminder/onboardingScreen.dart';

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final userName = TextEditingController();
  final emailAddress = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  final currentUser = FirebaseAuth.instance.currentUser;

  Future SignUp() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailAddress.text.trim(), password: password.text.trim());
      if (ConfirmPassword()) {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Congratulations!!!!'),
                  content: Text('You have signed Up Successfully'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        goToFrontPage(context);
                        SettingUpUserDatabase();
                      },
                      child: Text('Close'),
                    )
                  ],
                ));
      } // Create Alert, saying SignUp Successful

    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Alert !!!!'),
                  content: Text('Weak Password'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        goToFrontPage(context);
                        // SettingUpUserDatabase();
                      },
                      child: Text('Close'),
                    )
                  ],
                ));
        print('weak password!!');
      } else if (e.code == 'email-already-in-use') {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Alert !!!!'),
                  content: Text('Email already in use'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        goToFrontPage(context);
                        // SettingUpUserDatabase();
                      },
                      child: Text('Close'),
                    )
                  ],
                ));
        print('email-already-in-use');
      } else if (e.code == 'user-not-found') {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Alert !!!!'),
                  content: Text('User Not Found'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        goToFrontPage(context);
                        // SettingUpUserDatabase();
                      },
                      child: Text('Close'),
                    )
                  ],
                ));
        print('user-not-found!!');
      } else if (e.code == 'wrong-password') {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Alert !!!!'),
                  content: Text('Wrong Password'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        goToFrontPage(context);
                        // SettingUpUserDatabase();
                      },
                      child: Text('Close'),
                    )
                  ],
                ));
        print('wrong password!!');
      }
    } catch (e) {
      print(e);
    }
  }

  Future SettingUpUserDatabase() async {
    Map<String, dynamic> initData = {'wordStorage': []};

    var collection = await FirebaseFirestore.instance
        .collection('User')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set(initData)
        .then((_) => print("InitData Set"))
        .catchError((onError) => print("Add Error $onError"));
  }

  bool ConfirmPassword() {
    if (password.text.trim() == confirmPassword.text.trim()) {
      return true;
    } else {
      return false;
    }
  }

  void goToHomePage(context) => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MyHomePage(title: 'DE')));

  void goToFrontPage(context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => FrontPage()));

  @override
  void dispose() {
    emailAddress.dispose();
    password.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('SignUp', textDirection: TextDirection.ltr),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => {goToFrontPage(context)})
          ],
        ),
        backgroundColor: Colors.deepPurpleAccent[300],
        body: SingleChildScrollView(
            child: Center(
                child: Column(children: <Widget>[
          Container(
            width: 250,
            child: Icon(
              Icons.lock,
              size: 200,
            ),
          ),
          Container(
            width: 350,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16.0),
            margin: EdgeInsets.only(top: 20.0),
            decoration: const BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            child: TextField(
              toolbarOptions: const ToolbarOptions(
                  copy: true, cut: true, paste: true, selectAll: true),
              decoration: const InputDecoration.collapsed(
                  hintText: " Email ", fillColor: Colors.deepOrange),
              controller: emailAddress,
              cursorRadius: const Radius.circular(2.0),
              style: const TextStyle(
                  fontFamily: "OpenSans",
                  fontSize: 20.0,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold),
              scrollController: ScrollController(keepScrollOffset: mounted),
            ),
          ),
          Container(
            width: 350,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16.0),
            margin: EdgeInsets.only(top: 20.0),
            decoration: const BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            child: TextField(
              obscureText: true,
              toolbarOptions: const ToolbarOptions(
                  copy: true, cut: true, paste: true, selectAll: true),
              decoration: const InputDecoration.collapsed(
                  hintText: " Password ", fillColor: Colors.deepOrange),
              controller: password,
              cursorRadius: const Radius.circular(2.0),
              style: const TextStyle(
                  fontFamily: "OpenSans",
                  fontSize: 20.0,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold),
              scrollController: ScrollController(keepScrollOffset: mounted),
            ),
          ),
          Container(
            width: 350,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16.0),
            margin: EdgeInsets.only(top: 20.0),
            decoration: const BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            child: TextField(
              obscureText: true,
              toolbarOptions: const ToolbarOptions(
                  copy: true, cut: true, paste: true, selectAll: true),
              decoration: const InputDecoration.collapsed(
                  hintText: " Confirm Password ", fillColor: Colors.deepOrange),
              controller: confirmPassword,
              cursorRadius: const Radius.circular(2.0),
              style: const TextStyle(
                  fontFamily: "OpenSans",
                  fontSize: 20.0,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold),
              scrollController: ScrollController(keepScrollOffset: mounted),
            ),
          ),
          SizedBox(
            width: 10,
            height: 20,
          ),
          Container(
              height: 60,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(15.0),
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                  color: Colors.deepPurple[300],
                  borderRadius: BorderRadius.circular(8)),
              child: MaterialButton(
                  highlightElevation: 2.0,
                  splashColor: Colors.blue,
                  onPressed: () {
                    SignUp();
                  },
                  child: const Text(
                    "SignUp",
                    style: TextStyle(fontSize: 20.0, color: Colors.black),
                  )))
        ]))));
  }
}
