import 'package:flutter/material.dart';

import '../constants/app_content_padding.dart';
import '../constants/app_spacing_constant.dart';
import 'app_sheet_header.dart';

/// The inside of a bottom sheet: an [AppSheetHeader], then content that
/// scrolls when it has to, under a ceiling of [maxHeightFraction] of the
/// screen.
///
/// The header carries the sheet's two answers — leave on the left, commit on
/// the right. That pairing is what lets a picker mark a choice without
/// committing it: tapping a tile only moves the highlight, and nothing
/// leaves the sheet until the commit.
///
/// The ceiling is what keeps a sheet reading as a layer over the page — a
/// tall picker that grew to the status bar would just be a screen with a
/// rounded top. Content shorter than the ceiling still only takes what it
/// needs; the sheet does not stretch to meet it.
///
/// Only the *content* scrolls: the header stays pinned, and so does
/// [footer]. A sheet is a route, not a screen, so it clears the home
/// indicator itself rather than through `AppContentPadding.screen`.
///
/// Pass `isScrollControlled: true` when showing it — without that the sheet
/// route caps itself around half the screen and the ceiling never applies.
class AppSheetContent extends StatelessWidget {
  const AppSheetContent({
    required this.title,
    required this.child,
    this.onConfirm,
    this.action = AppSheetAction.confirm,
    this.footer,
    super.key,
  });

  /// Tallest a sheet may grow, as a fraction of the screen.
  static const double maxHeightFraction = 0.85;

  final String title;
  final Widget child;

  /// Applies whatever the sheet is collecting. Null hides the commit icon —
  /// for a sheet with nothing to confirm, or one that confirms in its
  /// [footer].
  final VoidCallback? onConfirm;

  /// Whether that commit adds something or overwrites something (see
  /// [AppSheetHeader]).
  final AppSheetAction action;

  /// Pinned under the scroll area, below the content.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final double maxHeight =
        MediaQuery.sizeOf(context).height * maxHeightFraction;
    // The keyboard, when the content has a field, then the home indicator:
    // whichever is there, the last row has to clear it.
    final double safeBottom =
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom +
        AppSpacingConstant.h16;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSheetHeader(title: title, onConfirm: onConfirm, action: action),
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
