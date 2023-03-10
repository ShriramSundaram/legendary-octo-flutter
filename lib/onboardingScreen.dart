import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'signupPage.dart';
import 'main.dart';

class OnBoardingScreen extends StatefulWidget {
  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreen();
}

class _OnBoardingScreen extends State<OnBoardingScreen> {
  final EmailController = TextEditingController();
  final PasswordController = TextEditingController();

  Future SignIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: EmailController.text.trim(),
          password: PasswordController.text.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // ignore: todo
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('ALERT!!!!'),
                  content: Text('user-not-found'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // SettingUpUserDatabase();
                        Navigator.pop(context);
                      },
                      child: Text('Close'),
                    )
                  ],
                ));
        //TODO: Pop Should Appear,
      } else if (e.code == 'wrong-password') {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('ALERT!!!!'),
                  content: Text('wrong-password'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // SettingUpUserDatabase();
                      },
                      child: Text('Close'),
                    )
                  ],
                ));
        print('Wrong password provided for that user.');
      }
    }
  }

  @override
  void dispose() {
    EmailController.dispose();
    PasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: IntroductionScreen(
        pages: [
          PageViewModel(
              title: 'Welcome to German Reminder',
              body:
                  ' This Application Helps you to improve your German vocabulary ',
              image: Image.asset('assets/german.png'),
              decoration: getPageDecoration()),
          PageViewModel(
              title: 'How Does it Work',
              body: ' Step:1 User Sign In \n Step:2 User Should Press PLAY Button (selects the random words from Generic Database and Display it) \n' +
                  'Step:3 User can Choose if the word needs to be reminded or not. If needed to be reminded, then User can select the X Time(HH::MM::SS) Above and Press SET TIME button. Automatically the selected word will be reminded after X time. If not then Press PLAY button again untill User finds non familier word',
              image: Image.asset('assets/works.png'),
              decoration: getPageDecoration()),
          PageViewModel(
              title: 'LogIn / Sign Up',
              bodyWidget: Column(
                children: [
                  Container(
                      width: 400,
                      height: 50,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16.0),
                      margin: EdgeInsets.only(left: 0.0),
                      decoration: const BoxDecoration(
                          color: Colors.yellow,
                          borderRadius:
                              BorderRadius.all(Radius.circular(30.0))),
                      child: TextField(
                        toolbarOptions: const ToolbarOptions(
                            copy: true,
                            cut: true,
                            paste: true,
                            selectAll: true),
                        decoration: const InputDecoration.collapsed(
                            hintText: "Email", fillColor: Colors.deepOrange),
                        controller: EmailController,
                        cursorRadius: const Radius.circular(2.0),
                        style: const TextStyle(
                            fontFamily: "OpenSans",
                            fontSize: 12.0,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold),
                      )),
                  Container(
                    width: 200,
                    height: 20,
                  ),
                  Container(
                      width: 400,
                      height: 50,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16.0),
                      margin: EdgeInsets.only(left: 0.0),
                      decoration: const BoxDecoration(
                          color: Colors.yellow,
                          borderRadius:
                              BorderRadius.all(Radius.circular(30.0))),
                      child: TextField(
                        obscureText: true,
                        toolbarOptions: const ToolbarOptions(
                            copy: true,
                            cut: true,
                            paste: true,
                            selectAll: true),
                        decoration: const InputDecoration.collapsed(
                            hintText: "Password", fillColor: Colors.deepOrange),
                        controller: PasswordController,
                        cursorRadius: const Radius.circular(2.0),
                        style: const TextStyle(
                            fontFamily: "OpenSans",
                            fontSize: 12.0,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold),
                      )),
                  Container(
                      width: 150,
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                          onPressed: () {
                            SignIn();
                          },
                          child: const Text(
                            "LogIn",
                            style:
                                TextStyle(fontSize: 13.0, color: Colors.black),
                          )))
                ],
              ),
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: 150,
                      padding: const EdgeInsets.all(8.0),
                      //margin: const EdgeInsets.only(right: 80),
                      child: ElevatedButton(
                          onPressed: () {
                            goToSignUpPage(context);
                          },
                          child: const Text(
                            "Sign Up",
                            style:
                                TextStyle(fontSize: 13.0, color: Colors.black),
                          )))
                ],
              ),
              image: Image.asset('assets/german.png'),
              decoration: getPageDecoration())
        ],
        onDone: () => goToOnBoardingScreen(context),
        showNextButton: true,
        next: const Text("Next", style: TextStyle(fontWeight: FontWeight.w900)),
        showBackButton: false,
        done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  void goToSignUpPage(context) => Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: (_) => SignUpPage()));

  void goToOnBoardingScreen(context) => Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: (_) => OnBoardingScreen()));

  PageDecoration getPageDecoration() => PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      bodyTextStyle: TextStyle(fontSize: 16),
      titlePadding: EdgeInsets.all(16).copyWith(bottom: 0),
      pageColor: Colors.white);
}
