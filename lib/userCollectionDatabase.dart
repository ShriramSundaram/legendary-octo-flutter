import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';

class UserCollectionDatabase extends StatefulWidget {
  const UserCollectionDatabase({Key? key}) : super(key: key);

  @override
  State<UserCollectionDatabase> createState() => _UserCollectionDatabaseState();
}

class _UserCollectionDatabaseState extends State<UserCollectionDatabase> {
  int selectedIndex = 0;
  final currentUser = FirebaseAuth.instance.currentUser;
  final List<String> doumentsIdList = [];
  CollectionReference user = FirebaseFirestore.instance.collection('User');

  FlutterTts flutterTts = FlutterTts();

  void speak(String text) async {
    await flutterTts.setLanguage("DE");
    //await flutterTts.setSpeechRate(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(" User Library "),
          centerTitle: true,
        ),
        body: Container(
            child: FutureBuilder<DocumentSnapshot>(
          future: user.doc(currentUser!.uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              Map<String, dynamic> dataCurr =
                  snapshot.data!.data() as Map<String, dynamic>;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: dataCurr['wordStorage'].length,
                scrollDirection: Axis.vertical,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return ListTile(
                      title: Text(dataCurr['wordStorage'][index]),
                      leading: Icon(
                        Icons.wordpress,
                        color: Colors.black,
                      ),
                      textColor: Colors.black,
                      minLeadingWidth: 5,
                      tileColor: selectedIndex == index ? Colors.blue : null,
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      trailing: GestureDetector(
                        onTap: () {
                          print('Selected index ' + selectedIndex.toString());
                          print('Selected Word ' +
                              dataCurr['wordStorage'][selectedIndex]
                                  .toString());
                          speak(dataCurr['wordStorage'][selectedIndex]
                              .toString());
                        },
                        child: Icon(Icons.spatial_audio_off_rounded),
                      ));
                },
              );
            } else {
              return ListView.builder(
                itemCount: doumentsIdList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Loading....'),
                  );
                },
              );
            }
          },
        )),
      );
}
