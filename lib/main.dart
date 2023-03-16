import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:germanreminder/frontPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'writeFile.dart';
import 'notification_api.dart';
import 'secondPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'databaseFirebase.dart';
import 'userCollectionDatabase.dart';
import 'onboardingScreen.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        // primarySwatch: Colors.green,
        brightness: Brightness.light,
        //primaryColor: Color.fromARGB(255, 0, 135, 245)
        //scaffoldBackgroundColor: Color.fromARGB(255, 177, 140, 240)
      ),
      home: FrontPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

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
  List<String> germanUserWordsList = [];

  final currentUser = FirebaseAuth.instance.currentUser;

  final myTextController = TextEditingController();

  List genericCollection = ["Guten Morgen", "Guten Abend"];

  FlutterTts flutterTts = FlutterTts();

  Future getFireBaseGenericCollection() async {
    DocumentSnapshot<Map<String, dynamic>> data = await FirebaseFirestore
        .instance
        .collection('Generic')
        .doc('GenericCollections')
        .get();
    print(data['wordStorage'][1]);
    for (var i = 0; i < data['wordStorage'].length; i++) {
      genericCollection.add(data['wordStorage'][i]);
    }
  }

  Future getFireBaseUserCollection() async {
    DocumentSnapshot<Map<String, dynamic>> data = await FirebaseFirestore
        .instance
        .collection('User')
        .doc(currentUser!.uid)
        .get();
    //print(data['wordStorage'][0]);
    if (data.exists) {
      for (var i = 0; i < data['wordStorage'].length; i++) {
        germanUserWordsList.add(data['wordStorage'][i]);
      }
    }
  }

  @override
  void initState() {
    getFireBaseGenericCollection();
    getFireBaseUserCollection();
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
          title: Text(genericCollection[_index]).data,
          body: "Reminder Word",
          description: 'The word',
          payload: Text(genericCollection[_index]).data);
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

  void OnClickedLoadDatabase() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => ViewGenericDatabase()));
  }

  void OnClickedUserDatabase() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => UserCollectionDatabase()));
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future speak(String text) async {
    await flutterTts.setLanguage("DE");
    //await flutterTts.setSpeechRate(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          child: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 250,
                  height: 35,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    " \t German Reminder",
                    style: TextStyle(
                        fontSize: 20.0,
                        fontFamily: "OpenSans",
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
            centerTitle: true,
            flexibleSpace: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.ltr,
              children: [
                SizedBox(
                  height: 62,
                ),
                Row(
                  children: [
                    SizedBox(
                      height: 40,
                    ),
                    Container(
                      width: 70,
                      child: Text(
                        "Welcome ",
                        style: GoogleFonts.roboto(
                            fontSize: 16, color: Colors.deepOrangeAccent),
                      ),
                    ),
                    Container(
                      width: 300,
                      child: Text(
                        currentUser!.email! + ' !',
                        style: GoogleFonts.roboto(
                            fontSize: 16, color: Colors.deepOrangeAccent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                onPressed: () {
                  initState();
                },
                icon: const Icon(Icons.help),
                tooltip: "Help",
                iconSize: 25,
                color: Colors.deepOrangeAccent,
                selectedIcon: Tooltip(
                  message: 'Help / Contact',
                ),
              ),
              IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                            title: Text(' Logout !!'),
                            content: Text(' Are you sure You want to Logout?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  signOut();
                                  Navigator.pop(context);
                                },
                                child: Text(' YES'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(' NO '),
                              )
                            ],
                          ));
                },
                icon: Icon(Icons.logout_rounded),
                tooltip: "LogOut",
                iconSize: 25,
                color: Colors.deepOrangeAccent,
              ),
            ],
          ),
          preferredSize: Size.fromHeight(78)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                width: 200.0,
                child: Text(
                  " Set timer to remind",
                  style: TextStyle(fontSize: 20.0, color: Colors.blue),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                      width: 95,
                      padding: const EdgeInsets.all(8.0),
                      child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton(
                            value: _dropDownValueHH,
                            borderRadius: BorderRadius.circular(20),
                            dropdownColor: Colors.blueAccent,
                            hint: Text("HH",
                                style: TextStyle(
                                    fontSize: 18.0, color: Colors.black)),
                            items: items_hh.map(buildMenuItem).toList(),
                            onChanged: (value) => {
                              hhInput = value as int,
                              setState(
                                () => this._dropDownValueHH = value,
                              )
                            },
                          ))),
                  Container(
                      width: 95,
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(right: 10),
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButton(
                          value: _dropDownValueMM,
                          borderRadius: BorderRadius.circular(20),
                          dropdownColor: Colors.blueAccent,
                          hint: Text("MM",
                              style: TextStyle(
                                  fontSize: 18.0, color: Colors.black)),
                          items: items_mm.map(buildMenuItem).toList(),
                          onChanged: (value) => {
                            mmInput = value as int,
                            setState(
                              () => this._dropDownValueMM = value,
                            )
                          },
                        ),
                      )),
                  Container(
                      width: 95,
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(right: 10),
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButton(
                          value: _dropDownValueSS,
                          borderRadius: BorderRadius.circular(20),
                          items: items_ss.map(buildMenuItem).toList(),
                          dropdownColor: Colors.blueAccent,
                          hint: Text("SS",
                              style: TextStyle(
                                  fontSize: 18.0, color: Colors.black)),
                          onChanged: (value) => {
                            ssInput = value as int,
                            setState(
                              () => this._dropDownValueSS = value,
                            )
                          },
                        ),
                      )),
                  Container(
                    width: 30,
                    child: IconButton(
                        onPressed: () {
                          if (hhInput != 0 || mmInput != 0 || ssInput != 0) {
                            timerStart();
                          }
                        },
                        splashRadius: 25.0,
                        splashColor: Colors.orangeAccent,
                        icon: const Icon(
                          Icons.access_alarm,
                          size: 30,
                          color: Colors.blueAccent,
                        )),
                  ),
                ],
              ),
              SizedBox(
                height: 40,
              ),
              Row(children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    width: 320,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                        //color: Color.fromARGB(255, 147, 13, 145),
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.all(Radius.circular(20.0))),
                    // margin: const EdgeInsets.symmetric(),
                    child: Text(
                      genericCollection[_index],
                      textScaleFactor: 5.0,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 5.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ]),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    color: Colors.deepOrangeAccent,
                    iconSize: 45.0,
                    tooltip: "Audio",
                    splashRadius: 25.0,
                    splashColor: Colors.orangeAccent,
                    onPressed: () {
                      speak(genericCollection[_index]);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    color: Colors.deepOrangeAccent,
                    iconSize: 45.0,
                    tooltip: "Start",
                    splashRadius: 25.0,
                    splashColor: Colors.orangeAccent,
                    onPressed: () {
                      setState(() {
                        //_index++;
                        var ran = Random();
                        _index = ran.nextInt(genericCollection.length);
                      });
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 40,
              ),
              Row(children: [
                Container(
                  width: 340,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    toolbarOptions: const ToolbarOptions(
                        copy: true, cut: true, paste: true, selectAll: true),
                    decoration: const InputDecoration(
                      hintText: "Add  New  Word",
                      fillColor: Colors.deepOrange,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(20.0))),
                    ),
                    controller: myTextController,
                    style: const TextStyle(
                        fontFamily: "OpenSans",
                        fontSize: 16.0,
                        color: Colors.black,
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
                    if (!genericCollection.contains(myTextController.text)) {
                      WriteToCloud(word: myTextController.text.trim());
                    } else {
                      // This Part of Code is not Working, Need to Investigate
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
            color: Colors.deepOrangeAccent,
            size: 30.0,
          ),
          IconButton(
            icon: const Icon(Icons.storage),
            color: Colors.deepOrangeAccent,
            tooltip: "Storage",
            splashRadius: 25.0,
            splashColor: Colors.orangeAccent,
            onPressed: () {
              OnClickedLoadDatabase();
            },
          ),
          IconButton(
            icon: const Icon(Icons.description_outlined),
            color: Colors.deepOrangeAccent,
            tooltip: "User Storage",
            splashRadius: 25.0,
            splashColor: Colors.orangeAccent,
            onPressed: () {
              OnClickedUserDatabase();
            },
          )
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future WriteToCloud({required String word}) async {
    final userData =
        FirebaseFirestore.instance.collection('User').doc(currentUser!.uid);
    if (!germanUserWordsList.contains(word)) {
      germanUserWordsList.add(word);
    } else {
      // ignore: todo
      // Widget Should Come or Pop up should come "WORD ALREDY EXIST!!!"
      showDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                title: Text('Alert !!!!'),
                content: Text('Word already present in UserDatabase'),
                actions: [
                  TextButton(
                    onPressed: () {
                      //OnClickedUserDatabase();
                      Navigator.pop(context);
                    },
                    child: Text('Close'),
                  )
                ],
              ));
    }

    final json = {'wordStorage': germanUserWordsList};

    // create document and write to Firebase
    await userData.set(json);
  }

  DropdownMenuItem<int> buildMenuItem(int item) => DropdownMenuItem(
      value: item,
      child: Text(
        item.toString(),
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ));
}
