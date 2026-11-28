import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:germanreminder/verifyEmailPage.dart';
import 'onboardingScreen.dart';
import 'data/account_store.dart';
import 'dart:async';
import 'reminder_runtime.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.waiting) {
            AccountStore.activeUid = snapshot.data?.uid;
            unawaited(ReminderRuntime.bindAccount(snapshot.data?.uid)
                .catchError((Object _) {}));
          }
          if (snapshot.hasData) {
            return VerifyEmailPage(key: ValueKey(snapshot.data!.uid));
          } else {
            return OnBoardingScreen();
          }
        },
      ),
    );
  }
}
