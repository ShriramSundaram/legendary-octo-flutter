import 'package:flutter/material.dart';
import 'package:germanreminder/main.dart';
import 'package:germanreminder/notification_api.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/utils.dart';

class SecondPage extends StatelessWidget {
  final String? payload;

  const SecondPage({Key? key, required this.payload}) : super(key: key);

  void goToHomeScreen(context) =>
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => MyHomePage(
                title: 'GermanReminder',
              )));

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text('NotificationPage'),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              payload ?? '',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Container(
                width: 320,
                height: 50,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16.0),
                margin: EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20)),
                child: MaterialButton(
                    highlightElevation: 2.0,
                    splashColor: Colors.blue,
                    onPressed: () {
                      goToHomeScreen(context);
                    },
                    child: const Text(
                      "Back",
                      style: TextStyle(fontSize: 16.0, color: Colors.black),
                    )))
          ],
        ),
      ));
}
