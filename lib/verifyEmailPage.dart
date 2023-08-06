import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:germanreminder/signupPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({Key? key}) : super(key: key);

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailVerified = false;
  Timer? timer;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    isEmailVerified = user!.emailVerified;

    if (!isEmailVerified) {
      SendVerificationEmail();

      timer = Timer.periodic(Duration(seconds: 3), (_) {
        CheckEmailVerified();
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();

    super.dispose();
  }

  Future CheckEmailVerified() async {
    // Need to reload after new user sign up
    await FirebaseAuth.instance.currentUser!.reload();
    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    // Cancel the timer once the Email is verified
    if (isEmailVerified) timer?.cancel();
  }

  Future SendVerificationEmail() async {
    try {
      user!.sendEmailVerification();
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

  void goToSignUpPage(context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => SignUpPage()));

  @override
  Widget build(BuildContext context) {
    var currentWidth = MediaQuery.of(context).size.width;
    var currentHeight = MediaQuery.of(context).size.width;

    if (isEmailVerified) {
      return MyHomePage(title: 'GermanReminder');
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Email'),
        automaticallyImplyLeading: false,
      ),
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          height: 50,
        ),
        Container(
            width: currentWidth * 0.9,
            height: currentHeight * 0.2,
            padding: EdgeInsets.symmetric(horizontal: currentWidth * 0.1),
            child: RichText(
              text: TextSpan(
                  text:
                      ' Please Verify the Email Address!! After Successful Email Verification will be automatically SignedIn ',
                  style: GoogleFonts.anekTamil(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 233, 45, 45))),
            )),
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
                  SendVerificationEmail();
                },
                child: const Text(
                  "Resend Verification Email",
                  style: TextStyle(fontSize: 16.0, color: Colors.black),
                ))),
        SizedBox(
          height: 15,
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
                  goToSignUpPage(context);
                },
                child: const Text(
                  "Back",
                  style: TextStyle(fontSize: 16.0, color: Colors.black),
                )))
      ]),
    );
  }
}
