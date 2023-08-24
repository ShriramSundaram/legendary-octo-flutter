import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:germanreminder/forgetPasswordPage.dart';
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

  bool _obscureText = true;

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
              title: " In just 3 steps!!!",
              bodyWidget: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            letterSpacing: 1.5,
                            fontFamily: "OpenSans"),
                        children: <TextSpan>[
                          TextSpan(
                              text: '\nStep 1 :',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20)),
                          TextSpan(text: ' User SignUp / LogIn '),
                          TextSpan(
                              text: '\n\nStep 2 :',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20)),
                          TextSpan(
                              text:
                                  ' User can press PLAY Button to display random words from Generic Database or Add Newly learnt words to User Database '),
                          TextSpan(
                              text: '\n\nStep 3 :',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20)),
                          TextSpan(
                              text: ' If displayed word needs to be reminded, User can select the Time(HH::MM::SS) Above and Press TimerIcon.\nThe selected word will be reminded after specified time.' +
                                  ' Alternatively user can click on PLAY button repeatedly until user finds unfamilier word.\nEnable/Allow Notification for this App.')
                        ]),
                  )
                ],
              ),
              image: Image.asset(
                'assets/works.png',
                height: 200,
                fit: BoxFit.fitHeight,
              ),
              decoration: getPageDecoration()),
          PageViewModel(
              title: " Login / SignUp \n",
              bodyWidget: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: 320,
                      height: 55,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16.0),
                      margin: EdgeInsets.only(left: 0.0),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Color.fromARGB(255, 148, 91, 247),
                              style: BorderStyle.solid),
                          borderRadius:
                              BorderRadius.all(Radius.circular(20.0))),
                      child: TextField(
                        decoration: InputDecoration(
                            hintText: "Email",
                            hintMaxLines: 1,
                            isCollapsed: true),
                        controller: EmailController,
                        cursorRadius: const Radius.circular(2.0),
                        style: TextStyle(
                            fontFamily: "OpenSans",
                            fontSize: 18.0,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      )),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                      width: 320,
                      height: 55,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16.0),
                      margin: EdgeInsets.only(left: 0.0),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Color.fromARGB(255, 148, 91, 247)),
                          borderRadius:
                              BorderRadius.all(Radius.circular(20.0))),
                      child: TextField(
                        obscureText: _obscureText,
                        toolbarOptions: const ToolbarOptions(
                            copy: true,
                            cut: true,
                            paste: true,
                            selectAll: true),
                        decoration: InputDecoration(
                            isCollapsed: true,
                            hintText: "Password",
                            hintMaxLines: 1,
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                              child: Icon(
                                  _obscureText
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Color.fromARGB(255, 148, 91, 247)),
                            )),
                        controller: PasswordController,
                        cursorRadius: const Radius.circular(2.0),
                        style: const TextStyle(
                            fontFamily: "OpenSans",
                            fontSize: 18.0,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      )),
                ],
              ),
              footer: SingleChildScrollView(
                  child: Column(children: [
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 45.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                              onTap: () {
                                goToForgotPasswordPage(context);
                              },
                              child: const Text(
                                "\nForgot Password ?",
                                style: TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold),
                              ))
                        ])),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 100),
                    Container(
                        width: 150,
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              SignIn();
                            },
                            style: ButtonStyle(backgroundColor:
                                MaterialStateProperty.resolveWith<Color?>(
                                    (states) {
                              if (states.contains(MaterialState.pressed)) {
                                return Colors.deepPurple; // Color when pressed
                              }
                              return Color.fromARGB(
                                  255, 175, 134, 246); // Default color
                            })),
                            child: const Text(
                              "LogIn",
                              style: TextStyle(
                                  fontSize: 15.0, color: Colors.black),
                            ))),
                    Container(
                        width: 150,
                        padding: const EdgeInsets.all(16.0),
                        //margin: const EdgeInsets.only(right: 80),
                        child: ElevatedButton(
                            onPressed: () {
                              goToSignUpPage(context);
                            },
                            style: ButtonStyle(backgroundColor:
                                MaterialStateProperty.resolveWith<Color?>(
                                    (states) {
                              if (states.contains(MaterialState.pressed)) {
                                return Colors.deepPurple; // Color when pressed
                              }
                              return Color.fromARGB(
                                  255, 175, 134, 246); // Default color
                            })),
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                  fontSize: 15.0, color: Colors.black),
                            )))
                  ],
                ),
              ])),
              image: Image.asset(
                'assets/german.png',
                height: 250,
                fit: BoxFit.fitHeight,
              ),
              decoration: getLoginPageDecoration())
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

  void goToForgotPasswordPage(context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => ForgetPasswordPage()));

  PageDecoration getPageDecoration() => PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      bodyTextStyle:
          TextStyle(fontSize: 16, letterSpacing: 1.5, fontFamily: "OpenSans"),
      titlePadding: EdgeInsets.all(16).copyWith(bottom: 0),
      pageColor: Colors.white);

  PageDecoration getLoginPageDecoration() => PageDecoration(
      titleTextStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      bodyTextStyle: TextStyle(fontSize: 16),
      titlePadding: EdgeInsets.all(8).copyWith(bottom: 0),
      pageColor: Colors.white);
}
