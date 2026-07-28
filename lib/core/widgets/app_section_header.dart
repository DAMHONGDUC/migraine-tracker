import 'package:flutter/material.dart';

import '../constants/app_content_padding.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_text_style.dart';

/// Label above a group of rows. Quiet by design; its spacing comes from
/// [AppContentPadding.sectionHeader], so callers just drop it between
/// groups — and pass `first: true` for the one at the top of a screen.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(this.title, {this.first = false, super.key});

  final String title;

  /// True for the first heading on a screen: the screen's own top gap has
  /// already placed it, so it drops the separator gap it would otherwise
  /// keep from the group above (see [AppContentPadding.sectionHeader]).
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppContentPadding.sectionHeader(first: first),
      child: Text(
        title,
        style: AppTextStyle.labelLarge.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
