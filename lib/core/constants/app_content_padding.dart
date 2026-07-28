import 'package:flutter/material.dart';

import '../widgets/glass/liquid_glass_theme.dart';
import '../widgets/pinned_filter_bar.dart';
import 'app_spacing_constant.dart';

/// Every screen's content insets, in one class.
///
/// The rule this encodes, for all content in the app:
/// - **[topGap] below the app bar** (the body scrolls *behind* the frosted
///   bar, so it is measured from the bar's bottom edge, not the viewport);
/// - **[bottomGap] above the safe area** — and on the five tab screens also
///   clear of the floating nav pill the content scrolls behind;
/// - **[horizontal] either side.**
///
/// The device insets live HERE, not in `AppScaffold`: a scaffold that wrapped
/// its body in a `SafeArea` would silently fight every screen that also has
/// to pad for something floating over it, and the two would double up. One
/// class computes it, every screen reads it, nothing adds it twice.
///
/// Floating chrome is the exception and asks for none of this: the shell's
/// nav pill and the log flow's step bar sit AT the safe area so they line up
/// with each other, and they read `MediaQuery` themselves.
abstract final class AppContentPadding {
  /// The gutter: 24 either side of any content.
  static double get horizontal => AppSpacingConstant.w24;

  /// Gap between the app bar and the first item of content. Separate from
  /// [bottomGap] on purpose: the two edges are different problems — this one
  /// is breathing room under chrome, that one is thumb room above the home
  /// indicator — and each can move without dragging the other with it.
  static double get topGap => AppSpacingConstant.h8;

  /// Gap between the last item — usually the bottom action — and the safe
  /// area below it.
  static double get bottomGap => AppSpacingConstant.h16;

  /// How far down the app bar reaches: status bar + toolbar while the bar is
  /// frosted glass (the body passes behind it), 0 when it is opaque and the
  /// body already starts below it.
  ///
  /// Use this only to *align* something to the bar — a pinned filter strip,
  /// a refresh indicator. Content wants [top], which adds the gap.
  ///
  /// Reads the status bar off the **view**, not off the ambient
  /// `MediaQuery`: `Scaffold` wraps its body in `removePadding(removeTop)`
  /// whenever there is an app bar, and that subtracts the status bar from
  /// `viewPadding.top` too. A body-side caller would get just
  /// [kToolbarHeight] where the screen's own build got the full height — and
  /// the bar would silently cover the first 47 logical pixels of content.
  /// The status bar is a property of the window, so the answer is the same
  /// anywhere in the tree.
  static double appBarInset(BuildContext context) => AppGlass.isSupported
      ? MediaQueryData.fromView(View.of(context)).padding.top + kToolbarHeight
      : 0;

  /// Top inset under a [PinnedFilterBar]: the app bar plus the strip pinned
  /// beneath it. What a scrollable behind that strip pads by, and what a
  /// refresh spinner drops below.
  static double belowPinnedFilterBar(BuildContext context) =>
      appBarInset(context) + PinnedFilterBar.barHeight;

  /// Padding for a section heading (`AppSectionHeader`): the gap that
  /// separates it from the group above, the list gutter, and the small gap
  /// down to its own rows.
  ///
  /// [first] drops the top gap. The screen's [topGap] has already placed the
  /// first heading; adding the separator on top of it is what made Settings
  /// start noticeably lower than Insights, whose first item is a plain card.
  ///
  /// The gutter here is the *list's* (16), not [horizontal]: the heading
  /// lines up with the left edge of the `ListTile`s under it.
  static EdgeInsets sectionHeader({bool first = false}) => EdgeInsets.fromLTRB(
    AppSpacingConstant.w16,
    first ? 0 : AppSpacingConstant.h24,
    AppSpacingConstant.w16,
    AppSpacingConstant.h8,
  );

  /// First item starts [topGap] below the app bar.
  static double top(BuildContext context) => appBarInset(context) + topGap;

  /// Last item ends [bottomGap] above the home indicator.
  ///
  /// The shell's five tab screens pass [floatingNav] — their content scrolls
  /// behind the nav pill, so it has to clear the pill's height too.
  static double bottom(BuildContext context, {bool floatingNav = false}) =>
      (floatingNav
          ? _navInset(context)
          : MediaQuery.viewPaddingOf(context).bottom) +
      bottomGap;

  /// The whole thing: gutter + [top] + [bottom].
  static EdgeInsets screen(BuildContext context, {bool floatingNav = false}) =>
      EdgeInsets.fromLTRB(
        horizontal,
        top(context),
        horizontal,
        bottom(context, floatingNav: floatingNav),
      );

  /// Same vertical insets, no gutter — for a list of `ListTile`s or cards
  /// that bring their own horizontal padding. Adding 24 on top of theirs
  /// would push the rows off the grid the rest of the app sits on.
  static EdgeInsets fullBleed(
    BuildContext context, {
    bool floatingNav = false,
  }) => EdgeInsets.only(
    top: top(context),
    bottom: bottom(context, floatingNav: floatingNav),
  );

  /// Bottom inset for a floating bar handed to `Scaffold.bottomNavigationBar`
  /// — the log flow's step bar. Unlike the shell's nav pill that one only
  /// floats where glass is supported; otherwise it takes a real layout slot
  /// and the body must NOT pad for it, so this collapses to the plain gap.
  static double bottomBar(BuildContext context) => AppGlass.isSupported
      ? _navInset(context) + bottomGap
      : MediaQuery.viewPaddingOf(context).bottom + bottomGap;

  /// Safe area + the floating bar's own height + the gap it hovers by.
  ///
  /// Reads `viewPadding` (the raw device inset), NOT `padding`: `Scaffold`
  /// rewrites the body's `MediaQuery.padding.bottom` to the bottom-bar slot
  /// height under `extendBody`, so a `padding` read returns different values
  /// above vs inside the body — `viewPadding` is stable everywhere.
  static double _navInset(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom +
      AppSpacingConstant.h68 + // shared bar height (nav pill + step bar)
      AppSpacingConstant.h8;
}
