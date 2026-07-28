import 'package:flutter/material.dart';

import '../constants/app_content_padding.dart';
import '../constants/app_spacing_constant.dart';
import '../theme/app_text_style.dart';

/// The inside of a bottom sheet: a title, then content that scrolls when it
/// has to, under a ceiling of [maxHeightFraction] of the screen.
///
/// The ceiling is what keeps a sheet reading as a layer over the page — a
/// tall picker that grew to the status bar would just be a screen with a
/// rounded top. Content shorter than the ceiling still only takes what it
/// needs; the sheet does not stretch to meet it.
///
/// Only the *content* scrolls: [title] stays pinned, and so does [footer]
/// (a save button that must not scroll out of reach). A sheet is a route,
/// not a screen, so it clears the home indicator itself rather than through
/// `AppContentPadding.screen`.
///
/// Pass `isScrollControlled: true` when showing it — without that the sheet
/// route caps itself around half the screen and the ceiling never applies.
class AppSheetContent extends StatelessWidget {
  const AppSheetContent({
    required this.title,
    required this.child,
    this.footer,
    super.key,
  });

  /// Tallest a sheet may grow, as a fraction of the screen.
  static const double maxHeightFraction = 0.85;

  final String title;
  final Widget child;

  /// Pinned under the scroll area — a confirm button, usually. Null for a
  /// picker where the pick itself closes the sheet.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final double maxHeight =
        MediaQuery.sizeOf(context).height * maxHeightFraction;
    final double safeBottom =
        MediaQuery.paddingOf(context).bottom + AppSpacingConstant.h16;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppContentPadding.horizontal,
              AppSpacingConstant.h8,
              AppContentPadding.horizontal,
              AppSpacingConstant.h16,
            ),
            child: Text(title, style: AppTextStyle.titleLarge),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppContentPadding.horizontal,
                0,
                AppContentPadding.horizontal,
                footer == null ? safeBottom : AppSpacingConstant.h16,
              ),
              child: child,
            ),
          ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppContentPadding.horizontal,
                0,
                AppContentPadding.horizontal,
                safeBottom,
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}
