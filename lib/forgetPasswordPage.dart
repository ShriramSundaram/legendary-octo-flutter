import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'frontPage.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final emailAddress = TextEditingController();

  @override
  void dispose() {
    emailAddress.dispose();
    super.dispose();
  }

  Future Resetpassword() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailAddress.text.trim());
      showDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                title: Text('Alert !!!!'),
                content: Text(
                    " Reset Password Link Sent to your mail !! Click EMail link to reset password "),
                actions: [
                  TextButton(
                    onPressed: () {
                      goToFrontPage(context);
                      // ignore: todo
                      // ClearUp the TextField(); TODO
                    },
                    child: Text('Close'),
                  )
                ],
              ));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Alert !!!!'),
                  content: Text('invalid-email'),
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
      } else if (e.code == 'missing-email') {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Alert !!!!'),
                  content: Text('missing-email'),
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
      } else if (e.code == 'user-not-found') {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Alert !!!!'),
                  content: Text('user-not-found'),
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
        print('email-already-in-use');
      } else if (e.code == 'invalid-continue-uri') {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Alert !!!!'),
                  content: Text('invalid-continue-uri'),
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
      } else if (e.code == 'unauthorized-continue-uri') {
        showDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: Text('Alert !!!!'),
                  content: Text('unauthorized-continue-uri'),
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
      }
    } catch (e) {
      showDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                title: Text('Alert !!!!'),
                content: Text(e.toString()),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password', textDirection: TextDirection.ltr),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => {goToFrontPage(context)})
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 90,
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: RichText(
                        text: TextSpan(
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                letterSpacing: 1.5,
                                fontFamily: "OpenSans"),
                            children: <TextSpan>[
                          TextSpan(
                              text: 'Forgot Password ?',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 25)),
                        ])),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                width: 320,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16.0),
                margin: EdgeInsets.only(right: 55.0),
                child: Text(
                  "Enter your registered Email Id to reset password ",
                  style: const TextStyle(
                      fontFamily: "OpenSans",
                      fontSize: 18.0,
                      letterSpacing: 1.5,
                      color: Colors.black,
                      fontWeight: FontWeight.normal),
                ),
              ),
              Container(
                width: 320,
                alignment: Alignment.center,
                margin: EdgeInsets.only(right: 35.0),
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: TextField(
                  toolbarOptions: const ToolbarOptions(
                      copy: true, cut: true, paste: true, selectAll: true),
                  decoration: const InputDecoration(
                      hintText: " Email ",
                      fillColor: Colors.deepOrange,
                      border: const OutlineInputBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(30)),
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 159, 125, 251))),
                      prefixIcon: Icon(Icons.email_rounded)),
                  controller: emailAddress,
                  cursorRadius: const Radius.circular(20.0),
                  style: const TextStyle(
                      fontFamily: "OpenSans",
                      fontSize: 20.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                  scrollController: ScrollController(keepScrollOffset: mounted),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Container(
                width: 320,
                alignment: Alignment.center,
                margin: EdgeInsets.only(right: 25.0),
                decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 159, 125, 251)),
                child: MaterialButton(
                  onPressed: () {
                    if (emailAddress != '' || emailAddress != null) {
                      Resetpassword();
                    } else {
                      showDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                                title: Text('Alert !!!!'),
                                content: Text(' Email Field is Empty!!'),
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
                    }
                  },
                  minWidth: 320,
                  height: 50,
                  child: Text(
                    " Send Email ",
                    style: const TextStyle(
                        fontFamily: "OpenSans",
                        fontSize: 20.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(
                height: 85,
              ),
            ]),
      ),
    );
  }

  void goToFrontPage(context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => FrontPage()));
}
