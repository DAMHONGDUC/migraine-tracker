import 'package:flutter/material.dart';

import '../constants/app_content_padding.dart';
import '../constants/app_spacing_constant.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_style.dart';
import 'buttons/app_bar_button.dart';

/// What the confirming icon of an [AppSheetHeader] is for — a prop, like
/// every other look in this app.
///
/// - [confirm] — a tick: the sheet is collecting an answer that did not
///   exist yet (pick a time for a new reminder).
/// - [edit] — a pencil: the sheet is changing something that already has a
///   value (correcting a logged attack, retyping its details). Same weight,
///   different promise, so the user can tell "I am adding" from "I am
///   overwriting" before they commit.
enum AppSheetAction { confirm, edit }

/// The header every bottom sheet with actions uses: leave on the left,
/// title in the middle, commit on the right.
///
/// Both wear their own frosted glass circle — the sheet is a flat opaque
/// panel, so a glass disc on it has real background to refract — and the
/// commit's glyph is teal, which is what still tells the action that writes
/// something from the one that abandons. Both are [AppBarButton]s, which is
/// what gives them the small icon, the invisible 48 target and the swell on
/// touch.
///
/// [onConfirm] null shows no commit at all (a picker where the tap itself is
/// the answer, a sheet that only reads). The slot stays reserved so the
/// title sits on the sheet's centre either way.
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({
    required this.title,
    this.onConfirm,
    this.action = AppSheetAction.confirm,
    super.key,
  });

  final String title;

  /// Applies whatever the sheet is collecting; null hides the icon.
  final VoidCallback? onConfirm;

  final AppSheetAction action;

  /// Inset of the row itself. Not the content gutter: the buttons carry
  /// [AppBarButton.tapSize] of invisible target around a much smaller glyph,
  /// so the row is pulled in by only the difference — which lands the glyphs
  /// themselves on the same vertical line as the content below them.
  static double get edgeInset {
    final double glyphInset =
        (AppBarButton.tapSize - AppBarButton.iconSize) / 2;

    return (AppContentPadding.horizontal - glyphInset).clamp(
      0,
      double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        edgeInset,
        AppSpacingConstant.h4,
        edgeInset,
        AppSpacingConstant.h16,
      ),
      child: Row(
        children: <Widget>[
          AppBarButton(
            icon: Icons.close,
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
            SizedBox(width: AppBarButton.tapSize)
          else
            AppBarButton(
              icon: switch (action) {
                AppSheetAction.confirm => Icons.check,
                AppSheetAction.edit => Icons.edit,
              },
              // Same glass disc as the X; the teal glyph is what still marks
              // this as the one action that writes something.
              color: AppColors.secondary,
              tooltip: context.l10n.commonDone,
              onPressed: onConfirm,
            ),
        ],
      ),
    );
  }
}
