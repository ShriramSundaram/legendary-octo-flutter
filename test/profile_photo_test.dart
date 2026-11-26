import 'package:germanreminder/data/account_store.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/editProfilePage.dart';
import 'package:hive/hive.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestImagePicker extends ImagePickerPlatform {
  XFile? selection;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async =>
      selection;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late TestImagePicker picker;
  late ImagePickerPlatform originalPicker;
  late Completer<void> editorClosed;
  final originalPath = File('assets/A1.png').absolute.path;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('profile-photo-test');
    Hive.init(directory.path);
    await Hive.openBox('LocalDatabase');
    AccountStore.activeUid = 'test-user';
    await AccountStore.current().put('UserName', 'Original name');
    await AccountStore.current().put('CurrentLevel', 'A2');
    SharedPreferences.setMockInitialValues(
        {AccountStore.current().key('ImagePath'): originalPath});
    editorClosed = Completer<void>();
    originalPicker = ImagePickerPlatform.instance;
    picker = TestImagePicker();
    ImagePickerPlatform.instance = picker;
  });

  tearDown(() async {
    ImagePickerPlatform.instance = originalPicker;
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> openEditor(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute<bool>(
                      builder: (_) => const EditProfilePage(),
                    ));
                    editorClosed.complete();
                  },
                  child: const Text('Edit profile'),
                ),
              )),
    ));
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
  }

  Future<void> selectPhoto(WidgetTester tester) async {
    picker.selection = XFile(File('assets/app_logo.png').absolute.path);
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.edit));
    });
    await tester.pumpAndSettle();
  }

  Future<void> saveEditor(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(editorClosed.isCompleted, isTrue);
  }

  testWidgets('Cancel discards a selected photo and other profile edits',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final box = AccountStore.current();
    await openEditor(tester);
    await selectPhoto(tester);
    expect(preferences.getString(AccountStore.current().key('ImagePath')),
        originalPath);
    expect(
        tester
            .widget<CircleAvatar>(find.byType(CircleAvatar).first)
            .backgroundImage,
        isA<FileImage>());
    await tester.enterText(find.byType(TextField), 'Unsaved name');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfilePage), findsNothing);
    expect(preferences.getString(AccountStore.current().key('ImagePath')),
        originalPath);
    expect(box.get('UserName'), 'Original name');
    expect(box.get('CurrentLevel'), 'A2');
  });

  testWidgets('Save persists the selected photo before leaving the editor',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await openEditor(tester);
    await selectPhoto(tester);
    expect(preferences.getString(AccountStore.current().key('ImagePath')),
        originalPath);
    await saveEditor(tester);
    expect(find.byType(EditProfilePage), findsNothing);
    expect(preferences.getString(AccountStore.current().key('ImagePath')),
        picker.selection!.path);
  });

  testWidgets('Cancelling the image picker keeps the saved photo',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await openEditor(tester);
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await saveEditor(tester);
    expect(preferences.getString(AccountStore.current().key('ImagePath')),
        originalPath);
  });
}
