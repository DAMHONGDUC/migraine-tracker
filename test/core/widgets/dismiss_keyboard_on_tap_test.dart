import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/widgets/dismiss_keyboard_on_tap.dart';

/// The app-wide rule: a tap on nothing puts the keyboard away, and a tap on something still reaches it.
void main() {
  late FocusNode fieldFocus;
  late int buttonTaps;

  Future<void> pump(WidgetTester tester) async {
    fieldFocus = FocusNode();
    addTearDown(fieldFocus.dispose);
    buttonTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: DismissKeyboardOnTap(
          child: Scaffold(
            body: Column(
              children: <Widget>[
                TextField(focusNode: fieldFocus),
                TextButton(
                  onPressed: () => buttonTaps++,
                  child: const Text('Save'),
                ),
                const Expanded(child: SizedBox.expand(key: Key('empty'))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a tap on empty space unfocuses the field', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(fieldFocus.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('empty')));
    await tester.pump();
    expect(fieldFocus.hasFocus, isFalse);
  });

  testWidgets('a tap on a control still reaches it', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    // The child wins the gesture arena, so the button fires.
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(buttonTaps, 1);
  });

  testWidgets('typing survives a tap inside the field', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(fieldFocus.hasFocus, isTrue);
    expect(find.text('hello'), findsOneWidget);
  });
}
