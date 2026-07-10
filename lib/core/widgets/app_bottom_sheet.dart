import 'package:flutter/material.dart';

/// Standard modal sheet for the app. Always use this instead of raw
/// [showModalBottomSheet]: `useRootNavigator: true` makes the sheet render
/// ABOVE the bottom navigation bar (the shell's branch navigators live
/// inside the Scaffold body, so a non-root sheet slides under the nav bar).
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: isScrollControlled,
    builder: builder,
  );
}
