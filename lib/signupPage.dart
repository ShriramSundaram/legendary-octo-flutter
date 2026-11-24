import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:germanreminder/frontPage.dart';

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

  void SignUp() async {
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
      } else {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Alert !!!!'),
                  content: Text('Not Matching Password \n'),
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
      } else if (e.code == 'operation-not-allowed') {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Alert !!!!'),
                  content: Text('Operation Not Allowed'),
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
      } else if (e.code == 'invalid-email') {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Alert !!!!'),
                  content: Text('invalid-email'),
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
      } else {
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
      }
    }
  }

  void SettingUpUserDatabase() async {
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

  void SendVerificationEmail() async {
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

  void goToFrontScreen(BuildContext context) {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => FrontPage()));
  }

  @override
  void dispose() {
    userName.dispose();
    emailAddress.dispose();
    password.dispose();
    confirmPassword.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('SignUp', textDirection: TextDirection.ltr),
          automaticallyImplyLeading: false,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => goToFrontScreen(context),
          ),
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
                border: Border.all(
                    color: Color.fromARGB(255, 175, 134, 246),
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            child: TextField(
              contextMenuBuilder: (context, editableTextState) {
                return AdaptiveTextSelectionToolbar.editableText(
                  editableTextState: editableTextState,
                );
              },
              decoration: const InputDecoration(
                  hintText: " Email ",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero),
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
                border: Border.all(
                    color: Color.fromARGB(255, 175, 134, 246),
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            child: TextField(
              obscureText: _obscureTextPassword,
              contextMenuBuilder: (context, editableTextState) {
                return AdaptiveTextSelectionToolbar.editableText(
                  editableTextState: editableTextState,
                );
              },
              decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: "Password",
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureTextPassword = !_obscureTextPassword;
                      });
                    },
                    icon: Icon(
                        _obscureTextPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Color.fromARGB(255, 175, 134, 246)),
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
                border: Border.all(
                    color: Color.fromARGB(255, 175, 134, 246),
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            child: TextField(
              obscureText: _obscureTextConfirmPassword,
              contextMenuBuilder: (context, editableTextState) {
                return AdaptiveTextSelectionToolbar.editableText(
                  editableTextState: editableTextState,
                );
              },
              decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: "Confirm Password",
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureTextConfirmPassword =
                            !_obscureTextConfirmPassword;
                      });
                    },
                    icon: Icon(
                        _obscureTextConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Color.fromARGB(255, 175, 134, 246)),
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
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 175, 134, 246),
                  borderRadius: BorderRadius.circular(20)),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 175, 134, 246),
                    foregroundColor: Colors.black,
                    minimumSize: Size(300, 50),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.pressed))
                          return Colors.deepPurple;
                        return null;
                      },
                    ),
                  ),
                  onPressed: () {
                    SignUp();
                  },
                  child: const Text(
                    "SignUp",
                    style: TextStyle(fontSize: 20.0, color: Colors.black),
                  ))),
          SizedBox(
            width: 10,
            height: 20,
          ),
          SizedBox(
            width: 250,
            child: TextButton(
              onPressed: () {
                goToFrontScreen(context);
              },
              child: const Text(
                "I already have an account !!",
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
