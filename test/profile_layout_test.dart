import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/profile_widgets.dart';

void main() {
  for (final size in [
    const Size(240, 640),
    const Size(393, 873),
    const Size(873, 393)
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Profile actions fit $size at text scale $scale',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        var backCount = 0;
        var editCount = 0;
        var testCount = 0;
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              padding: const EdgeInsets.only(bottom: 24),
            ),
            child: child!,
          ),
          home: ProfileView(
            name: 'A longer profile name that can wrap',
            email: 'long.profile.address@example.com',
            verified: true,
            level: 'A2',
            photo: const AssetImage('assets/app_logo.png'),
            onBack: () => backCount++,
            onEdit: () => editCount++,
            onTest: () => testCount++,
            onDelete: () => fail('Layout tests must not delete accounts'),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final back = find.widgetWithText(OutlinedButton, 'Back');
        final edit = find.widgetWithText(FilledButton, 'Edit');
        for (final button in [back, edit]) {
          final rect = tester.getRect(button);
          expect(rect.left, greaterThanOrEqualTo(16));
          expect(rect.right, lessThanOrEqualTo(size.width - 16));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 24));
          await tester.tap(button);
        }
        expect(backCount, 1);
        expect(editCount, 1);
        final delete = find.widgetWithText(OutlinedButton, 'Delete Account');
        if (size == const Size(393, 873) && scale == 1) {
          expect(tester.getRect(delete).bottom,
              lessThan(tester.getRect(back).top));
        }
        await tester.ensureVisible(delete);
        await tester.pumpAndSettle();
        expect(tester.getRect(delete).bottom,
            lessThanOrEqualTo(tester.getRect(back).top));
        final quiz = find.text('Quick vocabulary check');
        await tester.ensureVisible(quiz);
        await tester.tap(quiz);
        expect(testCount, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
