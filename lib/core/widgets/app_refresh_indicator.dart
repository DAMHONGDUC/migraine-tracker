import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import '../theme/app_colors.dart';
import 'main_app_bar.dart';

/// The app's pull-to-refresh wrapper — one themed [RefreshIndicator] so every
/// tab refreshes the same way. Wrap a scrollable [child] (use
/// [AlwaysScrollableScrollPhysics] on it so short content still pulls); for a
/// non-scrollable state (an empty state), wrap it in [ScrollFill] first.
///
/// The spinner drops in below the translucent app bar via [edgeOffset], so it
/// isn't hidden behind the glass chrome.
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    required this.onRefresh,
    required this.child,
    this.edgeOffset,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// Where the spinner drops in from. Defaults to the app-bar height plus a
  /// margin so the spinner clears the translucent chrome (the RefreshIndicator
  /// lives in the body, which is painted BEHIND the glass app bar — without
  /// the offset the spinner emerges under the bar and looks clipped). Pass 0
  /// when the wrapped scrollable already starts below other content.
  final double? edgeOffset;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      edgeOffset:
          edgeOffset ??
          MainAppBar.bodyTopInset(context) + AppSpacingConstant.h20,
      child: child,
    );
  }
}

/// Makes a non-scrollable widget (e.g. an [EmptyState]) fill the viewport and
/// still be pull-to-refreshable. Uses [SliverFillRemaining] rather than a
/// `LayoutBuilder` on purpose: a LayoutBuilder builds its child DURING layout,
/// and a Riverpod consumer resuming inside that layout-phase build can trigger
/// "setState() called during build". A sliver avoids that entirely.
class ScrollFill extends StatelessWidget {
  const ScrollFill({required this.child, this.topInset = 0, super.key});

  final Widget child;

  /// Space above the child so it clears the translucent app bar.
  final double topInset;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: topInset),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Runs [invalidate] (a tab's `ref.invalidate(...)` calls so its providers
/// reload), then holds briefly so the refresh spinner reads as deliberate even
/// when the (local-first) data reloads instantly. Use as a tab's `onRefresh`.
Future<void> pullRefresh(void Function() invalidate) async {
  invalidate();
  await Future<void>.delayed(const Duration(milliseconds: 350));
}
