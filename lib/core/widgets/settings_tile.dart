import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../theme/app_icon_constant.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_text_style.dart';

/// One Settings row: icon, title, and — when the row leads somewhere — a chevron at the end.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.iconColor,
    this.titleColor,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;

  /// What the row currently holds, shown just before the chevron.
  final String? value;

  /// Replaces the value + chevron cluster entirely (a badge, a spinner).
  final Widget? trailing;

  /// Tints the icon alone — a state the row wants to signal (premium).
  final Color? iconColor;

  /// Tints the label too — the destructive rows, which need the whole row to read as one.
  final Color? titleColor;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasChevron = onTap != null;
    final bool hasEnd = value != null || hasChevron;

    return ListTile(
      leading: SdIconV2(
        icon: icon,
        size: AppIconSize.row,
        color: iconColor ?? titleColor,
      ),
      title: Text(
        title,
        style: titleColor == null
            ? AppTextStyle.bodyLarge
            : AppTextStyle.bodyLarge.copyWith(color: titleColor),
      ),
      trailing:
          trailing ??
          (hasEnd ? _TileEnd(value: value, chevron: hasChevron) : null),
      onTap: onTap,
    );
  }
}

/// The value, then the chevron — the row's answer and its way in, in the one place the thumb is heading.
class _TileEnd extends StatelessWidget {
  const _TileEnd({required this.value, required this.chevron});

  final String? value;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (value != null)
          Flexible(
            child: Text(
              value!,
              style: AppTextStyle.bodyMedium.secondary,
              textAlign: TextAlign.end,
            ),
          ),
        if (value != null && chevron) SizedBox(width: SdSpacingConstant.w4),
        if (chevron)
          SdIconV2(
            icon: AppIconConstant.disclosure,
            size: AppIconSize.affordance,
            color: context.colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }
}
