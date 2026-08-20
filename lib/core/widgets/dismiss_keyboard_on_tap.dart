import 'package:flutter/material.dart';

/// Taps that land on nothing put the keyboard away.
///
/// Wrapped once around the whole app (`BaroEaseApp`), never per screen: a
/// rule that has to be remembered on every new field is a rule that is
/// already broken somewhere. It sits inside `MaterialApp.builder`, which
/// wraps the Navigator, so it covers dialogs and bottom sheets too — the
/// places a stuck keyboard hurts most, because it hides the very sheet the
/// user is typing into.
///
/// **Translucent, not opaque.** The detector has to see taps that land on
/// empty space without stealing the ones that land on something: a child
/// that recognises a tap wins the gesture arena, so buttons, tiles and the
/// fields themselves keep working and only the misses reach here.
///
/// [excludeFromSemantics] because this is not a control. Screen readers move
/// focus by their own rules and must not be told the page is one big button.
class DismissKeyboardOnTap extends StatelessWidget {
  const DismissKeyboardOnTap({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: () {
        final FocusNode? focused = FocusManager.instance.primaryFocus;
        // Only when something actually holds focus — unfocus() on a tree
        // with none walks the whole focus scope for nothing, on every tap
        // anywhere in the app.
        if (focused != null && focused.hasFocus) focused.unfocus();
      },
      child: child,
    );
  }
}
