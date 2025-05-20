import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ViewGenericDatabase extends StatefulWidget {
  final String GermanLevel;

  const ViewGenericDatabase({Key? key, required this.GermanLevel})
      : super(key: key);

  @override
  State<ViewGenericDatabase> createState() => _ViewGenericDatabaseState();
}

class _ViewGenericDatabaseState extends State<ViewGenericDatabase> {
  int selectedIndex = 0;
  final List<String> doumentsIdList = ["", "", ""];
  FlutterTts flutterTts = FlutterTts();
  //Map<String, dynamic> copyVocabulary = {};

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

  Map<String, dynamic> dataCurr = {};

  bool firstTime = true;

  @override
  void initState() {
    getData();
    super.initState();
  }

  Future<void> getData() async {
    final DocumentSnapshot snapshot = await user.doc(widget.GermanLevel).get();
    if (snapshot.exists) {
      print('DataPresent');
      dataCurr = snapshot.data() as Map<String, dynamic>;
      print(dataCurr);
    }

    if (firstTime) {
      runFilter('');
      firstTime = false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(" Generic Collection " +
              widget.GermanLevel.replaceAll('GenericCollections', '')),
          centerTitle: true,
        ),
        body: Column(
          children: [
            SizedBox(
              height: 20,
            ),
            TextField(
              onChanged: (value) {
                runFilter(value);
              },
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(bottom: 5),
                  labelText: 'Search',
                  labelStyle: TextStyle(
                    color: Colors.black, // Customize the label text color
                    fontWeight: FontWeight.normal, // Customize the font weight
                    fontSize: 20.0, // Customize the font size
                  ),
                  prefixIcon: Icon(Icons.wordpress),
                  suffixIcon: Icon(Icons.search),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: "OpenSans")),
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(
              child: Container(
                  child: FutureBuilder<DocumentSnapshot>(
                future: user.doc(widget.GermanLevel).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: (dataCurr['filteredWords'] as List<dynamic>?)
                              ?.length ??
                          0,
                      scrollDirection: Axis.vertical,
                      physics: BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return ListTile(
                            title: Text(dataCurr['filteredWords'][index]),
                            leading: Icon(Icons.wordpress, color: Colors.black),
                            textColor: Colors.black,
                            minLeadingWidth: 5,
                            tileColor:
                                selectedIndex == index ? Colors.blue : null,
                            onTap: () {
                              setState(() {
                                selectedIndex = index;
                              });
                            },
                            trailing: GestureDetector(
                              onTap: () {
                                print('Selected index ' +
                                    selectedIndex.toString());
                                print('Selected Word ' +
                                    dataCurr['filteredWords'][selectedIndex]
                                        .toString());
                                speak(dataCurr['filteredWords'][selectedIndex]
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
            ),
          ],
        ),
      );

  void runFilter(String enterWord) {
    enterWord = enterWord.toLowerCase();
    setState(() {
      if (enterWord.isEmpty || enterWord == null) {
        dataCurr['filteredWords'] = dataCurr['wordStorage'];
      } else {
        dataCurr['filteredWords'] =
            (dataCurr['wordStorage'] as List<dynamic>?)?.where((word) {
          return word.toLowerCase().contains(enterWord);
        }).toList();
      }
    });
  }
}
