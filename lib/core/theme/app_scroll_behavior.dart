import 'package:flutter/material.dart';

/// App-wide scroll behaviour: keep the iOS bounce feel, but only when the content actually overflows.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();
}
