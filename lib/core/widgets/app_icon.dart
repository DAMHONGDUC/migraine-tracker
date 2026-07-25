import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';

/// The app's only icon widget — every icon renders through this so sizing
/// stays consistent across the app (hard rule: no raw [Icon] in feature or
/// core code, only here).
///
/// [size] always resolves to a concrete value: it defaults to
/// [AppSpacingConstant.r24] (Material's 24, run through screenutil) so every
/// icon has an explicit size rather than inheriting an ambient one. [color]
/// falls back to the surrounding [IconTheme] when null.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {this.size, this.color, super.key});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size ?? AppSpacingConstant.r24, color: color);
  }
}
