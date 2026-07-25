import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_text_style.dart';

/// The label above a group of rows in a long settings-style list.
///
/// Quiet by design: small, tinted with the primary colour, and carrying its
/// own spacing so callers just drop it between groups. It is a label, not a
/// heading users read one by one — the rows underneath are the content.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacingConstant.w16,
        AppSpacingConstant.h24,
        AppSpacingConstant.w16,
        AppSpacingConstant.h8,
      ),
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
