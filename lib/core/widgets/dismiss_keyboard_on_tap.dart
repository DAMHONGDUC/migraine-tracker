import 'package:flutter/material.dart';

/// Taps that land on nothing put the keyboard away.
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
        // Only when something actually holds focus — unfocus() on a tree with none walks the whole focus scope for nothing, on every tap anywhere in the app.
        if (focused != null && focused.hasFocus) focused.unfocus();
      },
      child: child,
    );
  }
}
