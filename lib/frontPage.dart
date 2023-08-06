import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:germanreminder/verifyEmailPage.dart';
import 'onboardingScreen.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return VerifyEmailPage();
          } else {
            return OnBoardingScreen();
          }
        },
      ),
    );
  }
}
