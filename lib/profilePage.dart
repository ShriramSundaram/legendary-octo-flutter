import 'data/account_store.dart';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:germanreminder/editProfilePage.dart';
import 'package:germanreminder/frontPage.dart';
import 'package:germanreminder/main.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'germanBasicTest.dart';
import 'profile_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? localPath;
  TextEditingController userNameEditor = TextEditingController();
  String? userName;
  String? germanLevel;

  // Initialize the object for Hive
  final hiveDatabase = AccountStore.current();

  Future<void> goToEditProfilePage(BuildContext context) async {
    final saved = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => EditProfilePage()));
    if (!mounted || saved != true) return;
    setState(() {
      userName = hiveDatabase.get('UserName', defaultValue: '');
      germanLevel = hiveDatabase.get('CurrentLevel', defaultValue: '');
    });
    loadImage();
  }

  void goToHomePage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MyHomePage(
              title: 'German Reminder',
            )));
  }

  @override
  void initState() {
    super.initState();

    if (hiveDatabase.containsKey('UserName')) {
      userName = hiveDatabase.get('UserName');
    } else {
      userName = '';
    }

    if (hiveDatabase.containsKey('CurrentLevel')) {
      germanLevel = hiveDatabase.get('CurrentLevel');
    } else {
      germanLevel = '';
    }

    loadImage();
  }

  void deleteUserAccount() async {
    try {
      await FirebaseAuth.instance.currentUser!.delete();
      if (!mounted) return;

      showDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                title: Text('Alert !!!!'),
                content: Text('Your Account is Deleted!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      goToFrontScreen(context);
                    },
                    child: Text('Close'),
                  )
                ],
              ));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      showDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                title: Text('Alert !!!!'),
                content: Text(e.toString()),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Close'),
                  )
                ],
              ));
    }
  }

  void goToFrontScreen(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const FrontPage()), (_) => false);
  }

  void loadImage() async {
    try {
      SharedPreferences imagePath = await SharedPreferences.getInstance();
      if (!mounted) return;

      if (imagePath.containsKey(hiveDatabase.key('ImagePath'))) {
        setState(() {
          localPath = imagePath.getString(hiveDatabase.key('ImagePath'));
        });
      } else {
        setState(() {
          localPath = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      if (!mounted) return;
      setState(() {
        localPath = null;
      });
    }
  }

  void goToGermanBasicTest(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => germanBasicTest()));
  }

  void confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Delete Account !!'),
        content: const Text('Are you sure You want to Delete Account?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              deleteUserAccount();
            },
            child: const Text('YES'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('NO'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider photo;
    if (localPath != null && localPath!.isNotEmpty) {
      photo = FileImage(File(localPath!));
    } else {
      photo = const AssetImage('assets/app_logo.png');
    }
    return ProfileView(
      name: userName ?? '',
      email: user?.email ?? '',
      verified: user?.emailVerified ?? false,
      level: germanLevel ?? '',
      photo: photo,
      onTest: () => goToGermanBasicTest(context),
      onDelete: confirmDeleteAccount,
      onBack: () => goToHomePage(context),
      onEdit: () => goToEditProfilePage(context),
    );
  }
}
