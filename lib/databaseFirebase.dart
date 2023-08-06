import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ViewGenericDatabase extends StatefulWidget {
  const ViewGenericDatabase({Key? key}) : super(key: key);

  @override
  State<ViewGenericDatabase> createState() => _ViewGenericDatabaseState();
}

class _ViewGenericDatabaseState extends State<ViewGenericDatabase> {
  int selectedIndex = 0;
  final List<String> doumentsIdList = [];
  FlutterTts flutterTts = FlutterTts();

  // Get the documents Id's from Firebase - NOT USED NOW, FUTURE USE
  Future getDocuIdFireBase() async {
    await FirebaseFirestore.instance.collection('User').get().then(
          (snapshot) => snapshot.docs.forEach((element) {
            doumentsIdList.add(element.reference.id);
          }),
        );
  }

  void speak(String text) async {
    await flutterTts.setLanguage("DE");
    //await flutterTts.setSpeechRate(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  CollectionReference user = FirebaseFirestore.instance.collection('Generic');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(" Generic Collection "),
          centerTitle: true,
        ),
        body: Container(
            child: FutureBuilder<DocumentSnapshot>(
          future: user.doc('GenericCollections').get(),
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
                      leading: Icon(Icons.wordpress, color: Colors.black),
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
