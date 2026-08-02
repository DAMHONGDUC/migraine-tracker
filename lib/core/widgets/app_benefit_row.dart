import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_text_style.dart';
import 'app_icon.dart';

/// One "here is what you get" row: icon, title, supporting line. Shared by
/// the paywall and the login pitch, which sell different things the same way.
class AppBenefitRow extends StatelessWidget {
  const AppBenefitRow({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacingConstant.h16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcon(icon: icon, color: context.colorScheme.primary),
          SizedBox(width: AppSpacingConstant.w16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTextStyle.titleMedium),
                SizedBox(height: AppSpacingConstant.h4),
                Text(body, style: AppTextStyle.bodyMedium.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
