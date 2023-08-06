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
      FirebaseAuth.instance
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
      showDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                title: Text('Alert !!!!'),
                content: Text(e.message.toString()),
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
              Container(
                width: 320,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16.0),
                margin: EdgeInsets.only(top: 20.0),
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
                decoration: const BoxDecoration(shape: BoxShape.rectangle),
                child: TextField(
                  toolbarOptions: const ToolbarOptions(
                      copy: true, cut: true, paste: true, selectAll: true),
                  decoration: const InputDecoration(
                      hintText: " Email ",
                      fillColor: Colors.deepOrange,
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 159, 125, 251))),
                      prefixIcon: Icon(Icons.email_rounded)),
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
              SizedBox(
                height: 30,
              ),
              Container(
                width: 320,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 159, 125, 251)),
                child: MaterialButton(
                  onPressed: () {
                    Resetpassword();
                  },
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
