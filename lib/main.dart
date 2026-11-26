import 'dart:async';
import 'dart:math';
import 'data/learning_repository.dart';
import 'data/learning_models.dart';
import 'data/account_store.dart';
import 'data/offline_vocabulary.dart';
import 'data/offline_vocabulary_loader.dart';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:germanreminder/frontPage.dart';
import 'package:germanreminder/profilePage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:responsive_framework/responsive_framework.dart';
// import 'package:responsive_framework/responsive_wrapper.dart';
import 'notification_api.dart';
import 'home_widgets.dart';
import 'secondPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'databaseFirebase.dart';
import 'userCollectionDatabase.dart';
import 'content_library_page.dart';
import 'review_session_page.dart';
import 'package:flip_card/flip_card.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  const appCheckDebugToken =
      String.fromEnvironment('FIREBASE_APP_CHECK_DEBUG_TOKEN');
  await FirebaseAppCheck.instance.activate(
    // Emulator debug tokens must be registered in Firebase App Check.
    providerAndroid: kDebugMode
        ? AndroidDebugProvider(
            debugToken: appCheckDebugToken.isEmpty ? null : appCheckDebugToken,
          )
        : const AndroidPlayIntegrityProvider(),
  );
  if (kDebugMode) {
    // Validate wireless setup without logging the token or blocking offline UI.
    unawaited(FirebaseAppCheck.instance.getToken(true).then<void>((token) {
      debugPrint(token?.isNotEmpty == true
          ? 'Wireless App Check validation: accepted'
          : 'Wireless App Check validation: failed');
    }, onError: (Object _) {
      debugPrint('Wireless App Check validation: failed');
    }));
  }
  await Hive.initFlutter();

  // Initialize notifications
  NotificationApi.initialize();
  await NotificationApi.requestPermissions();
  // Enable edge-to-edge
  //SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Initialize local database
  await Hive.openBox('LocalDatabase');
  FirebaseAuth.instance.authStateChanges().listen((user) {
    AccountStore.activeUid = user?.uid;
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: BouncingScrollWrapper.builder(context, child!),
        breakpoints: [
          Breakpoint(start: 0, end: 450, name: 'MOBILE'),
          Breakpoint(start: 451, end: 800, name: 'TABLET'),
          Breakpoint(start: 801, end: 1000, name: 'TABLET'),
          Breakpoint(start: 1001, end: 1200, name: 'DESKTOP'),
          Breakpoint(start: 1201, end: 2460, name: '4K'),
        ],
      ),
      debugShowCheckedModeBanner: false,
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

  String? databaseSelection;

  final hiveDB = AccountStore.current();

  final currentUser = FirebaseAuth.instance.currentUser;
  final learningRepository = LearningRepository.current();

  final myTextController = TextEditingController();

  List genericCollection = ["Guten Morgen", "Guten Abend"];

  FlutterTts flutterTts = FlutterTts();

  void getFireBaseGenericCollection() => loadGeneric('GenericCollections');
  void getFireBaseGenericCollectionA2() => loadGeneric('GenericCollectionsA2');
  void getFireBaseGenericCollectionB1() => loadGeneric('GenericCollectionsB1');
  void getFireBaseGenericCollectionB2() => loadGeneric('GenericCollectionsB2');
  void getFireBaseGenericCollectionC1() => loadGeneric('GenericCollectionsC1');
  void getFireBaseGenericCollectionC2() => loadGeneric('GenericCollectionsC2');

  Future<void> loadGeneric(String id) async {
    try {
      final vocabulary = await loadOfflineVocabulary();
      final words = vocabulary
          .atLevel(OfflineVocabulary.levelForCollection(id))
          .map((word) => word.display)
          .toList();
      if (words.isEmpty)
        throw const FormatException('No vocabulary for this level');
      if (!mounted) return;
      setState(() {
        genericCollection = words;
        _index = 0;
      });
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Could not load offline vocabulary. Please try again.')));
    }
  }

  @override
  void initState() {
    super.initState();

    if (hiveDB.containsKey('CurrentLevel')) {
      print('Yeah it contains');
      if ((hiveDB.get('CurrentLevel')) == 'A1') {
        print('Yeah it contains A1');
        getFireBaseGenericCollection();
        setState(() {
          databaseSelection = 'GenericCollections';
        });
      }
      if ((hiveDB.get('CurrentLevel')) == 'A2') {
        print('Yeah it contains A2');
        getFireBaseGenericCollectionA2();
        setState(() {
          databaseSelection = 'GenericCollectionsA2';
        });
      }
      if ((hiveDB.get('CurrentLevel')) == 'B1') {
        print('Yeah it contains B1');
        getFireBaseGenericCollectionB1();
        databaseSelection = 'GenericCollectionsB1';
      }
      if ((hiveDB.get('CurrentLevel')) == 'B2') {
        print('Yeah it contains B1');
        getFireBaseGenericCollectionB2();
        databaseSelection = 'GenericCollectionsB2';
      }
      if ((hiveDB.get('CurrentLevel')) == 'C1') {
        print('Yeah it contains B1');
        getFireBaseGenericCollectionC1();
        databaseSelection = 'GenericCollectionsC1';
      }
      if ((hiveDB.get('CurrentLevel')) == 'C2') {
        getFireBaseGenericCollectionC2();
        databaseSelection = 'GenericCollectionsC2';
      }
    } else {
      getFireBaseGenericCollection();
      databaseSelection = 'GenericCollections';
    }
  }

  void notificationEnable() {
    NotificationApi.initialize();
    NotificationApi.requestPermissions();
    listenNotification();
  }

  void timerStart() {
    Timer(Duration(hours: (hhInput), minutes: (mmInput), seconds: (ssInput)),
        () {
      NotificationApi.showNotification(
          title: Text(genericCollection[_index]).data,
          body: "Reminder Word",
          description: 'The word',
          payload: Text(genericCollection[_index]).data);
    });
  }

  void onDidReceiveNotificationResponse(payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (context) => SecondPage(payload: payload)),
    );
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
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ViewGenericDatabase(
              GermanLevel: databaseSelection!,
            )));
  }

  void OnClickedUserDatabase() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => UserCollectionDatabase()));
  }

  void OnClickedProfilePage() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => ProfilePage()));
  }

  void goToFrontScreen(context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => FrontPage()));

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const FrontPage()), (_) => false);
  }

  void speak(String text) async {
    await flutterTts.setLanguage("DE");
    //await flutterTts.setSpeechRate(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

  @override
  Widget build(BuildContext context) {
    var currentWidth = MediaQuery.of(context).size.width;
    final double statusbarHeight = MediaQuery.of(context).padding.top;
    print(statusbarHeight);
    return Scaffold(
      appBar: PreferredSize(
          child: AppBar(
            title: Center(
              child: Container(
                width: currentWidth * 0.6,
                height: statusbarHeight,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  " German Reminder",
                  style: GoogleFonts.roboto(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            centerTitle: true,
            flexibleSpace: SafeArea(
              child: SizedBox(
                height: statusbarHeight * 5,
                child: Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        child: Text(
                          "Welcome ",
                          style: GoogleFonts.roboto(
                              fontSize: 16, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: 'Learning library',
                icon: const Icon(Icons.library_books),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ContentLibraryPage())),
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
          preferredSize: Size.fromHeight(80)),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => ReviewSessionPage(
                                level: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                                        .contains(hiveDB.get('CurrentLevel'))
                                    ? hiveDB.get('CurrentLevel') as String
                                    : 'A1'))),
                    icon: const Icon(Icons.school),
                    label: const Text('Review words'),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  SizedBox(
                    width: 300.0,
                    child: Text(
                      " Set time to remind",
                      style: TextStyle(
                          fontSize: 20.0,
                          color: Color.fromRGBO(33, 150, 243, 1)),
                    ),
                  ),
                  ReminderTimeSelector(
                    values: [
                      _dropDownValueHH,
                      _dropDownValueMM,
                      _dropDownValueSS
                    ],
                    items: [items_hh, items_mm, items_ss],
                    onChanged: [
                      (value) => setState(() {
                            hhInput = value ?? 0;
                            _dropDownValueHH = value;
                          }),
                      (value) => setState(() {
                            mmInput = value ?? 0;
                            _dropDownValueMM = value;
                          }),
                      (value) => setState(() {
                            ssInput = value ?? 0;
                            _dropDownValueSS = value;
                          }),
                    ],
                    onStart: () {
                      if (hhInput != 0 || mmInput != 0 || ssInput != 0)
                        timerStart();
                    },
                  ),
                  SizedBox(
                    height: 70,
                  ),
                  FlipCard(
                    key: cardKey,
                    flipOnTouch: false,
                    front: HomeWordCard(word: genericCollection[_index]),
                    back: HomeWordCard(word: genericCollection[_index]),
                  ),
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
                            cardKey.currentState!.toggleCard();
                            var ran = Random();
                            _index = ran.nextInt(genericCollection.length);
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 70,
                  ),
                  HomeWordInput(controller: myTextController),
                  IconButton(
                    icon: const Icon(Icons.add),
                    color: Colors.deepOrangeAccent,
                    splashRadius: 25.0,
                    splashColor: Colors.yellowAccent,
                    iconSize: 45.0,
                    onPressed: () {
                      setState(() {
                        if (!genericCollection
                                .contains(myTextController.text.trim()) &&
                            myTextController.text.trim().isNotEmpty) {
                          WriteToCloud(word: myTextController.text.trim());
                        } else if (myTextController.text.trim().isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: Text('Alert'),
                              content: Text('Word is already present'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Close'),
                                ),
                              ],
                            ),
                          );
                        }
                        myTextController.text = "";
                      });
                    },
                  ),
                  SizedBox(
                    height: 40,
                  ),
                ],
              ),
            ),
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
          ),
          IconButton(
            icon: const Icon(Icons.face_sharp),
            color: Colors.deepOrangeAccent,
            tooltip: "User Page",
            splashRadius: 25.0,
            splashColor: Colors.orangeAccent,
            onPressed: () {
              OnClickedProfilePage();
            },
          )
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void WriteToCloud({required String word}) async {
    if (word.isEmpty) return;
    try {
      await learningRepository.ensureWord(PersonalWord.fromText(word));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Word saved.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not save your word. Please try again.')));
    }
  }

  DropdownMenuItem<int> buildMenuItem(int item) => DropdownMenuItem(
      value: item,
      child: Text(
        item.toString(),
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ));
}
