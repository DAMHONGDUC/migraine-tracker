import 'package:flutter/material.dart';

/// App-wide scroll behaviour: keep the iOS bounce feel, but only when the
/// content actually overflows. The Material default wraps iOS physics in
/// [AlwaysScrollableScrollPhysics], which lets every list drag/bounce even
/// when it fits on screen — distracting motion we don't want (hard rule 3:
/// calm UI). Plain [BouncingScrollPhysics] refuses user scrolls when there
/// is no scrollable extent.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();
}
