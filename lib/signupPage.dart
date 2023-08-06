import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:germanreminder/frontPage.dart';
import 'package:germanreminder/main.dart';
import 'package:germanreminder/onboardingScreen.dart';
import 'package:germanreminder/verifyEmailPage.dart';

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

  bool _obscureTextConfirmPassword = true;
  bool _obscureTextPassword = true;

  Future SignUp() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailAddress.text.trim(), password: password.text.trim());
      if (ConfirmPassword()) {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Congratulations!!!!'),
                  content: Text(
                      'You have signed Up Successfully, Verification Email sent to your mail id'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        goToFrontScreen(context);
                        SettingUpUserDatabase();
                        SendVerificationEmail();
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
                  content: Text('Weak Password \n' +
                      'Mininum 8 Characters (AlphaNumeric)'),
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
                        goToFrontScreen(context);
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
                        goToFrontScreen(context);
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
                        goToFrontScreen(context);
                        // SettingUpUserDatabase();
                      },
                      child: Text('Close'),
                    )
                  ],
                ));
        print('wrong password!!');
      }
    }
    (e) {
      showDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                title: Text('Alert !!!!'),
                content: Text(e.code.toString()),
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
    };
  }

  Future SettingUpUserDatabase() async {
    Map<String, dynamic> initData = {'wordStorage': []};

    await FirebaseFirestore.instance
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

  Future SendVerificationEmail() async {
    try {
      currentUser!.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
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

  void goToFrontScreen(context) => Navigator.of(context)
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
          centerTitle: true,
          actions: [
            IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => {goToFrontScreen(context)})
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
              size: 170,
            ),
          ),
          Container(
            height: 15,
          ),
          Container(
            width: 320,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16.0),
            margin: EdgeInsets.only(top: 20.0),
            decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.blue, style: BorderStyle.solid),
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
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
              scrollController: ScrollController(keepScrollOffset: mounted),
            ),
          ),
          Container(
            width: 320,
            height: 60,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16.0),
            margin: EdgeInsets.only(top: 20.0),
            decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.blue, style: BorderStyle.solid),
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            child: TextField(
              obscureText: _obscureTextPassword,
              toolbarOptions: const ToolbarOptions(
                  copy: true, cut: true, paste: true, selectAll: true),
              decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: "Password",
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscureTextPassword = !_obscureTextPassword;
                      });
                    },
                    child: Icon(_obscureTextPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                  )),
              controller: password,
              cursorRadius: const Radius.circular(2.0),
              style: const TextStyle(
                  fontFamily: "OpenSans",
                  fontSize: 20.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
              scrollController: ScrollController(keepScrollOffset: mounted),
            ),
          ),
          Container(
            width: 320,
            height: 60,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16.0),
            margin: EdgeInsets.only(top: 20.0),
            decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.blue, style: BorderStyle.solid),
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            child: TextField(
              obscureText: _obscureTextConfirmPassword,
              toolbarOptions: const ToolbarOptions(
                  copy: true, cut: true, paste: true, selectAll: true),
              decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: "Confirm Password",
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscureTextConfirmPassword =
                            !_obscureTextConfirmPassword;
                      });
                    },
                    child: Icon(_obscureTextConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                  )),
              controller: confirmPassword,
              cursorRadius: const Radius.circular(2.0),
              style: const TextStyle(
                  fontFamily: "OpenSans",
                  fontSize: 20.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
              scrollController: ScrollController(keepScrollOffset: mounted),
            ),
          ),
          SizedBox(
            width: 10,
            height: 40,
          ),
          Container(
              width: 320,
              height: 50,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16.0),
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(20)),
              child: MaterialButton(
                  highlightElevation: 2.0,
                  splashColor: Colors.blue,
                  onPressed: () {
                    SignUp();
                  },
                  child: const Text(
                    "SignUp",
                    style: TextStyle(fontSize: 16.0, color: Colors.black),
                  ))),
          SizedBox(
            width: 10,
            height: 20,
          ),
          SizedBox(
            width: 250,
            child: GestureDetector(
              onTap: () {
                goToFrontScreen(context);
              },
              child: Text(
                "\tI already have an account !! ",
                style: TextStyle(
                    fontSize: 18.0,
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ]))));
  }
}
