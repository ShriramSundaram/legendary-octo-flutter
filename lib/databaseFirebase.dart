import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewGenericDatabase extends StatelessWidget {
  final List<String> doumentsIdList = [];
  ViewGenericDatabase({Key? key}) : super(key: key);

  // Get the documents Id's from Firebase - NOT USED NOW, FUTURE USE
  Future getDocuIdFireBase() async {
    await FirebaseFirestore.instance.collection('User').get().then(
          (snapshot) => snapshot.docs.forEach((element) {
            doumentsIdList.add(element.reference.id);
          }),
        );
  }

  CollectionReference user = FirebaseFirestore.instance.collection('Generic');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(" Generic Database "),
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
                    tileColor: Colors.amber,
                    leading: Icon(Icons.wordpress),
                    textColor: Colors.cyan,
                    minLeadingWidth: 5,
                  );
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
