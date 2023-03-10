import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserCollectionDatabase extends StatelessWidget {
  final List<String> doumentsIdList = [];
  UserCollectionDatabase({Key? key}) : super(key: key);

  final currentUser = FirebaseAuth.instance.currentUser;

  CollectionReference user = FirebaseFirestore.instance.collection('User');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(" User Database "),
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
