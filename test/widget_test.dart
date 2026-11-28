import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/home_widgets.dart';

void main() {
  for (final size in [
    const Size(240, 640),
    const Size(320, 640),
    const Size(393, 873),
    const Size(800, 600),
    const Size(873, 393),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Home controls fit $size with text scale $scale',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FlipCard(
                        front: const HomeWordCard(
                            word: 'Donaudampfschifffahrtsgesellschaft'),
                        back: const HomeWordCard(word: 'Guten Morgen'),
                      ),
                      HomeWordInput(controller: controller),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final type in [HomeWordCard, HomeWordInput]) {
          for (final element in find.byType(type).first.evaluate()) {
            final box = element.renderObject! as RenderBox;
            final left = box.localToGlobal(Offset.zero).dx;
            expect(left, greaterThanOrEqualTo(0));
            expect(left + box.size.width, lessThanOrEqualTo(size.width));
          }
        }
        await tester.ensureVisible(find.byType(HomeWordInput));
        await tester.enterText(find.byType(TextField), 'Neues Wort');
        expect(controller.text, 'Neues Wort');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
