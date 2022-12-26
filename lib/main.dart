import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'writeFile.dart';
import 'notification_api.dart';
import 'secondPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        title: 'German Reminder App',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;
  final FileUtils germanWords = FileUtils();

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int hhInput = 0;
  int mmInput = 0;
  int ssInput = 0;
  int _index = 0;
  final items_hh = [00, 01, 02, 03, 04, 05];
  final items_mm = [00, 05, 10, 15, 20, 30];
  final items_ss = [00, 05, 10, 15, 20, 30];
  int? _dropDownValueHH;
  int? _dropDownValueMM;
  int? _dropDownValueSS;

  final myTextController = TextEditingController();

  List wordsGerman = ["Guten Morgen", "Guten Abend"];

  @override
  void initState() {
    widget.germanWords.readDataFromFile().then((value) {
      setState(() {
        print(value);
        for (var i = 0; i < value.length; i++) {
          wordsGerman.add(value[i]);
        }
      });
    });
  }

  void notificationEnable() {
    NotificationApi.initialize();
    listenNotification();
  }

  void timerStart() {
    notificationEnable();
    Timer(Duration(hours: (hhInput), minutes: (mmInput), seconds: (ssInput)),
        () {
      NotificationApi.showNotification(
          title: Text(wordsGerman[_index]).data,
          body: "Reminder Word",
          description: 'The word',
          payload: Text(wordsGerman[_index]).data);
    });
  }

  void listenNotification() =>
      NotificationApi.onNotifications.stream.listen((onClickedNotification));

  void onClickedNotification(String? payload) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => SecondPage(
                payload: payload,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('German Reminder App'),
        actions: [
          Text(
            "Update New Words",
            softWrap: true,
            textAlign: TextAlign.center,
            textScaleFactor: 1,
            maxLines: 2,
          ),
          IconButton(
            onPressed: () {
              initState();
            },
            icon: const Icon(Icons.upload_rounded),
            tooltip: "Updated New Words",
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                width: 100.0,
                child: Text(
                  " Set Timer",
                  style: TextStyle(fontSize: 20.0, color: Colors.blue),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                      width: 75,
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(right: 10),
                      child: DropdownButton(
                        value: _dropDownValueHH,
                        dropdownColor: Colors.blueAccent,
                        hint: Text("HH",
                            style:
                                TextStyle(fontSize: 15.0, color: Colors.black)),
                        items: items_hh.map(buildMenuItem).toList(),
                        onChanged: (value) => {
                          if (_dropDownValueHH is int)
                            {
                              hhInput = value as int,
                            },
                          setState(
                            () => this._dropDownValueHH = value as int,
                          )
                        },
                      )),
                  Container(
                    width: 75,
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.only(right: 10),
                    child: DropdownButton(
                      value: _dropDownValueMM,
                      dropdownColor: Colors.blueAccent,
                      hint: Text("MM",
                          style:
                              TextStyle(fontSize: 15.0, color: Colors.black)),
                      items: items_mm.map(buildMenuItem).toList(),
                      onChanged: (value) => {
                        if (_dropDownValueMM is int)
                          {
                            mmInput = value as int,
                          },
                        setState(
                          () => this._dropDownValueMM = value as int,
                        )
                      },
                    ),
                  ),
                  Container(
                    width: 75,
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.only(right: 10),
                    child: DropdownButton(
                      value: _dropDownValueSS,
                      items: items_ss.map(buildMenuItem).toList(),
                      dropdownColor: Colors.blueAccent,
                      hint: Text("SS",
                          style:
                              TextStyle(fontSize: 15.0, color: Colors.black)),
                      onChanged: (value) => {
                        if (_dropDownValueSS is int) {ssInput = value as int},
                        setState(
                          () => this._dropDownValueSS = value as int,
                        )
                      },
                    ),
                  ),
                ],
              ),
              Container(
                  width: 85,
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.only(left: 10),
                  child: ElevatedButton(
                      onPressed: () {
                        if (hhInput != 0 || mmInput != 0 || ssInput != 0) {
                          timerStart();
                        }
                      },
                      child: const Text(
                        "Set Time",
                        style: TextStyle(fontSize: 13.0, color: Colors.black),
                      ))),
              const Text(
                'German Remainder',
                style: TextStyle(
                    fontSize: 45.0,
                    fontFamily: "Waterfall",
                    fontStyle: FontStyle.normal),
              ),
              Container(
                  width: 300,
                  height: 50,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20.0)))),
              Row(children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.all(Radius.circular(20.0))),
                  // margin: const EdgeInsets.symmetric(),
                  child: Text(
                    wordsGerman[_index],
                    textScaleFactor: 5.0,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.orangeAccent, fontSize: 5.0),
                  ),
                  // color: Colors.green,
                ),
              ]),
              IconButton(
                icon: const Icon(Icons.play_arrow),
                color: Colors.orangeAccent,
                iconSize: 45.0,
                tooltip: "Start",
                splashRadius: 25.0,
                splashColor: Colors.orangeAccent,
                onPressed: () {
                  setState(() {
                    //_index++;
                    var ran = Random();
                    _index = ran.nextInt(wordsGerman.length);
                  });
                },
              ),
              Container(
                  width: 300,
                  height: 50,
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20.0)))),
              Row(children: [
                Container(
                  width: 300,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16.0),
                  margin: EdgeInsets.only(left: 0.0),
                  decoration: const BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.all(Radius.circular(20.0))),
                  child: TextField(
                    toolbarOptions: const ToolbarOptions(
                        copy: true, cut: true, paste: true, selectAll: true),
                    decoration: const InputDecoration.collapsed(
                        hintText: "Add  New  Word",
                        fillColor: Colors.deepOrange),
                    controller: myTextController,
                    cursorRadius: const Radius.circular(2.0),
                    style: const TextStyle(
                        fontFamily: "OpenSans",
                        fontSize: 20.0,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold),
                    scrollController:
                        ScrollController(keepScrollOffset: mounted),
                  ),
                )
              ]),
              IconButton(
                icon: const Icon(Icons.add),
                color: Colors.deepOrangeAccent,
                splashRadius: 25.0,
                splashColor: Colors.yellowAccent,
                iconSize: 45.0,
                onPressed: () {
                  setState(() {
                    if (!wordsGerman.contains(myTextController.text)) {
                      widget.germanWords.saveToFile(myTextController.text);
                    } else {
                      const AnimatedDefaultTextStyle(
                          child: Text("Word is alread present"),
                          style: TextStyle(fontSize: 12.0),
                          duration: Duration(seconds: 3));
                    }
                    myTextController.text = "";
                  });
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        color: Colors.blue,
        backgroundColor: Colors.white,
        items: <Widget>[
          const Icon(
            Icons.home,
            color: Colors.orangeAccent,
            size: 30.0,
          )
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  DropdownMenuItem<int> buildMenuItem(int item) => DropdownMenuItem(
      value: item,
      child: Text(
        item.toString(),
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ));
}
