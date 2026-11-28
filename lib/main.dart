import 'dart:async';
import 'dart:math';

import 'data/account_store.dart';
import 'data/offline_vocabulary.dart';
import 'data/offline_vocabulary_loader.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:germanreminder/frontPage.dart';

import 'package:hive_flutter/adapters.dart';
import 'package:responsive_framework/responsive_framework.dart';
// import 'package:responsive_framework/responsive_wrapper.dart';
import 'notification_api.dart';
import 'home_widgets.dart';
import 'reminder_panel.dart';
import 'reminder_runtime.dart';
import 'reminder_destination.dart';
import 'data/reminder_models.dart';
import 'data/reminder_logout.dart';
import 'package:firebase_core/firebase_core.dart';

import 'learning_shell.dart';
import 'learning_progress_panel.dart';

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

  // Enable edge-to-edge
  //SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Initialize local database
  await Hive.openBox('LocalDatabase');
  await NotificationApi.instance.initialize();
  AccountStore.activeUid = FirebaseAuth.instance.currentUser?.uid;
  FirebaseAuth.instance.authStateChanges().listen((user) {
    AccountStore.activeUid = user?.uid;
    unawaited(ReminderRuntime.bindAccount(user?.uid).catchError((Object _) {
      debugPrint('Study reminder settings could not be restored.');
    }));
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
      navigatorObservers: [learningProgressRoutes],
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
  int _index = 0;
  int _homeRevision = 0;
  List<OfflineWord> _offlineWords = [];
  bool _routingReminder = false;
  String? _activeReminderPayload;
  late final VoidCallback _notificationHandler =
      () => unawaited(_routeReminder());

  String? databaseSelection;

  final hiveDB = AccountStore.current();

  final currentUser = FirebaseAuth.instance.currentUser;

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
      final entries =
          vocabulary.atLevel(OfflineVocabulary.levelForCollection(id));
      final words = entries.map((word) => word.display).toList();
      if (words.isEmpty)
        throw const FormatException('No vocabulary for this level');
      if (!mounted) return;
      setState(() {
        genericCollection = words;
        _offlineWords = entries;
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
    NotificationApi.registerTapHandler(_notificationHandler);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notificationHandler());

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

  Future<void> _routeReminder() async {
    if (_routingReminder) {
      if (NotificationApi.pendingPayload == _activeReminderPayload)
        NotificationApi.pendingPayload = null;
      return;
    }
    if (!mounted ||
        NotificationApi.pendingPayload == null ||
        FirebaseAuth.instance.currentUser?.emailVerified != true) return;
    _routingReminder = true;
    var navigated = false;
    try {
      final controller = await ReminderRuntime.current();
      if (!mounted) return;
      final raw = NotificationApi.pendingPayload;
      final payload = ReminderPayload.parse(raw);
      NotificationApi.pendingPayload = null;
      if (payload == null || !controller.accepts(payload)) return;
      _activeReminderPayload = raw;
      navigated = true;
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReminderDestination(payload: payload)));
    } catch (_) {
      /* Keep a pending notification until authenticated settings are ready. */
    } finally {
      _routingReminder = false;
      _activeReminderPayload = null;
      if (navigated && mounted && NotificationApi.pendingPayload != null)
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _notificationHandler());
    }
  }

  @override
  void dispose() {
    NotificationApi.unregisterTapHandler(_notificationHandler);

    unawaited(flutterTts.stop());
    super.dispose();
  }

  void goToFrontScreen(context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => FrontPage()));

  void signOut() async {
    try {
      final cleaned = await signOutWithReminderCleanup(
        cleanup: ReminderRuntime.disableBeforeSignOut,
        signOut: FirebaseAuth.instance.signOut,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const FrontPage()), (_) => false);
      if (!cleaned)
        messenger.showSnackBar(const SnackBar(
            content: Text(
                'Signed out. Reminder cleanup could not be confirmed and will be retried.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not sign out. Please try again.')));
    }
  }

  void speak(String text) async {
    await flutterTts.setLanguage("DE");
    //await flutterTts.setSpeechRate(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) => LearningShell(
      home: _buildHome(context),
      onDestinationChanged: () {
        unawaited(
            flutterTts.stop().then<void>((_) {}).catchError((Object _) {}));
      },
      onHomeSelected: () {
        if (mounted) setState(() => _homeRevision++);
      });

  Widget _buildHome(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('German Reminder'), actions: [
        IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                        title: const Text('Log out?'),
                        content: const Text(
                            'You can sign back in to continue learning.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancel')),
                          FilledButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                signOut();
                              },
                              child: const Text('Log out'))
                        ]))),
      ]),
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
                  LearningProgressPanel(
                      key: ValueKey(_homeRevision),
                      level: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                              .contains(hiveDB.get('CurrentLevel'))
                          ? hiveDB.get('CurrentLevel') as String
                          : 'A1'),
                  const SizedBox(height: 12),
                  const SizedBox(height: 20),
                  ReminderPanel(
                    level: OfflineVocabulary.levelForCollection(
                        databaseSelection ?? 'GenericCollections'),
                    itemId:
                        _offlineWords.isEmpty ? null : _offlineWords[_index].id,
                    word: genericCollection[_index],
                  ),
                  const SizedBox(height: 28),
                  const Text('Reminder word',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  HomeWordCard(word: genericCollection[_index]),
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
                        tooltip: "Choose another reminder word",
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
                    height: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<int> buildMenuItem(int item) => DropdownMenuItem(
      value: item,
      child: Text(
        item.toString(),
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ));
}
