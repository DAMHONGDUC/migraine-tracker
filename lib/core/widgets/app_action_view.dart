import 'package:flutter/material.dart';

import '../constants/app_content_padding.dart';
import '../constants/app_spacing_constant.dart';

/// Body layout for any screen that is "content, then an action at the
/// bottom": the sign-in screen, the account screen, the premium screen.
///
/// [content] sits at the top, [actions] hug the bottom edge, and the space
/// between them is whatever is left over. It scrolls once the two together
/// outgrow one viewport — which long locales and large accessibility text
/// sizes make a matter of when, not if — so pass it straight as
/// `AppScaffold.body` and leave the scroll view to this widget.
///
/// Three things it owns, so no screen has to remember them (CLAUDE.md
/// § Code style):
/// - the vertical insets, straight from [AppContentPadding] — so [content]
///   must not open with a gap of its own, or the two stack up;
/// - the minimum height, which is what gives `spaceBetween` free space to
///   push the actions down — without it the column shrink-wraps and the
///   buttons drift into the middle under short content.
///
/// [actions] is a stretched column, so buttons come out full width and the
/// same width as each other whatever their labels say.
class AppActionView extends StatelessWidget {
  const AppActionView({
    required this.content,
    required this.actions,
    this.contentPadding,
    this.actionsPadding,
    this.actionSpacing,
    super.key,
  });

  final Widget content;

  /// Bottom-pinned, in order. Usually one or two [AppButton]s.
  final List<Widget> actions;

  /// Horizontal insets for [content]. Defaults to the app's
  /// [AppContentPadding.horizontal] gutter; pass [EdgeInsets.zero] for
  /// full-bleed rows (a `ListTile` brings its own).
  final EdgeInsetsGeometry? contentPadding;

  /// Horizontal insets for [actions]. Defaults to the same gutter — buttons
  /// stay inset even where the content above is full-bleed.
  final EdgeInsetsGeometry? actionsPadding;

  /// Gap between action rows. Defaults to [AppSpacingConstant.h8].
  final double? actionSpacing;

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry contentInsets =
        contentPadding ??
        EdgeInsets.symmetric(horizontal: AppContentPadding.horizontal);
    final EdgeInsetsGeometry actionInsets =
        actionsPadding ??
        EdgeInsets.symmetric(horizontal: AppContentPadding.horizontal);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.only(
                top: AppContentPadding.top(context),
                bottom: AppContentPadding.bottom(context),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(padding: contentInsets, child: content),
                  Padding(
                    padding: actionInsets,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: actionSpacing ?? AppSpacingConstant.h8,
                      children: actions,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
