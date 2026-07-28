import 'package:flutter/material.dart';

import '../constants/app_content_padding.dart';
import '../constants/app_spacing_constant.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_text_style.dart';
import 'app_icon.dart';

/// The inside of a bottom sheet: a header, then content that scrolls when it
/// has to, under a ceiling of [maxHeightFraction] of the screen.
///
/// The header is the sheet's two answers — an X on the left that leaves
/// without applying anything, and, when [onConfirm] is given, a tick on the
/// right that applies. That pairing is what lets a picker mark a choice
/// without committing it: tapping a tile only moves the highlight, and
/// nothing leaves the sheet until the tick.
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
    this.footer,
    super.key,
  });

  /// Tallest a sheet may grow, as a fraction of the screen.
  static const double maxHeightFraction = 0.85;

  final String title;
  final Widget child;

  /// Applies whatever the sheet is collecting. Null hides the tick — for a
  /// sheet with nothing to confirm, or one that confirms in its [footer].
  final VoidCallback? onConfirm;

  /// Pinned under the scroll area, below the content.
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
          _Header(title: title, onConfirm: onConfirm),
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

/// Leave on the left, apply on the right, title between them. The empty slot
/// where the tick would go is kept when there is none, so the title sits on
/// the sheet's centre either way.
class _Header extends StatelessWidget {
  const _Header({required this.title, this.onConfirm});

  final String title;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacingConstant.h8),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const AppIcon(Icons.close),
            tooltip: context.l10n.commonClose,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.titleMedium,
            ),
          ),
          if (onConfirm == null)
            SizedBox(width: AppSpacingConstant.w48)
          else
            IconButton(
              icon: AppIcon(Icons.check, color: context.colorScheme.primary),
              tooltip: context.l10n.commonDone,
              onPressed: onConfirm,
            ),
        ],
      ),
    );
  }
}
