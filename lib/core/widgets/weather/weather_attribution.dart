import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:system_design/index.dart';

import '../../constants/legal_url_constant.dart';
import '../../extensions/context_extensions.dart';
import '../../services/link_launcher_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';

/// The Apple Weather mark, linking to Apple's attribution page.
class WeatherAttribution extends ConsumerWidget {
  const WeatherAttribution({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SdPressableScaleV2(
        onTap: () => unawaited(
          ref
              .read(linkLauncherProvider)
              .open(LegalUrlConstant.weatherAttribution),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SdIconV2(
              icon: SimpleIcons.apple,
              size: SdSpacingConstant.r12,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: SdSpacingConstant.w4),
            Text(
              context.l10n.weatherAttribution,
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
