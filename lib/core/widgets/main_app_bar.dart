import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_leading_button.dart';
import 'glass/glass_circle.dart';
import 'glass/liquid_glass_theme.dart';

/// The app's single [AppBar]. Every screen gets it via [AppScaffold] rather
/// than constructing an [AppBar] directly.
///
/// Chrome style: the bar itself is NOT a glass slab — its strip is the app
/// background colour (translucent) over a backdrop blur, so there is no
/// visible edge/divider and content scrolling behind it (via
/// `extendBodyBehindAppBar`) simply blurs out. The Liquid Glass treatment
/// is applied per element instead: the leading/back button and icon actions
/// each sit in their own glass circle. Scroll-under bodies should pad their
/// top by [bodyTopInset] so their first item starts below the bar.
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
    super.key,
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  /// Top inset a scroll-under body needs so its first item clears the bar:
  /// status bar + toolbar.
  ///
  /// Reads `viewPadding` (the raw device inset), NOT `padding`: Scaffold
  /// rewrites the body's `MediaQuery.padding.top` to the app-bar height
  /// under `extendBodyBehindAppBar`, so a `padding` read returns different
  /// values above vs inside the body — `viewPadding` is stable everywhere.
  /// Returns 0 when glass is disabled — the bar is then opaque and the body
  /// sits below it normally.
  static double bodyTopInset(BuildContext context) => AppGlass.isSupported
      ? MediaQuery.viewPaddingOf(context).top + kToolbarHeight
      : 0;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    // Every screen's leading button — explicit or auto-inserted for a
    // pushed route that can pop — resolves through AppLeadingButton, glass
    // on or off, so there is exactly one leading widget for the whole app
    // rather than this bar and stock AppBar each growing their own.
    // automaticallyImplyLeading: false below stops AppBar from also trying
    // to insert its own default back button on top of this.
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    Widget? resolvedLeading =
        leading ?? (canPop ? const AppLeadingButton() : null);

    if (!AppGlass.isSupported) {
      return AppBar(
        title: title,
        actions: actions,
        leading: resolvedLeading,
        automaticallyImplyLeading: false,
        bottom: bottom,
      );
    }

    // Glass per element: the leading button and plain icon actions get
    // their own circles. Composite actions (filter pill, view toggle)
    // already carry their own surface, so they pass through untouched.
    if (resolvedLeading != null) {
      // Centered, not bare: AppBar forces the leading into a tight
      // `leadingWidth` box (56 by default), which would stretch the glass
      // circle into a wider oval than the (naturally sized) action circles.
      // Centering keeps it a 48×48 circle matching the actions.
      resolvedLeading = Center(child: GlassCircle(child: resolvedLeading));
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: kChromeGlass.blur,
          sigmaY: kChromeGlass.blur,
        ),
        // Same colour as the app background — no divider, no distinct slab;
        // the translucency lets the blurred content glow through faintly.
        child: ColoredBox(
          color: AppColors.background.withValues(alpha: 0.65),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: title,
            leading: resolvedLeading,
            automaticallyImplyLeading: false,
            actions: [
              for (final action in actions ?? const <Widget>[])
                if (action is IconButton)
                  GlassCircle(child: action)
                else
                  action,
            ],
            bottom: bottom,
          ),
        ),
      ),
    );
  }
}
