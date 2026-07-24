import 'package:flutter/material.dart';

import '../../constants/app_spacing_constant.dart';
import '../../theme/app_colors.dart';

/// A surface panel wrapping one chart, so stacked charts read as distinct
/// cards on the near-black background rather than bleeding into one another.
/// Shared by the History → Chart deck and the dashboard's severity card.
/// Titles live inside each chart widget.
class ChartCard extends StatelessWidget {
  const ChartCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacingConstant.w16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacingConstant.r16),
      ),
      child: child,
    );
  }
}
