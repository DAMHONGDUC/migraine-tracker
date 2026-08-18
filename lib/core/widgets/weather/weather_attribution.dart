import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../constants/legal_url_constant.dart';
import '../../extensions/context_extensions.dart';
import '../../services/link_launcher_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';

/// The " Weather" mark, linking to Apple's attribution page.
///
/// **A condition of using WeatherKit, not a courtesy.** It must appear on
/// every surface that draws weather data, and App Review checks — so this
/// lives in the body that renders the forecast rather than being placed by
/// each screen, which is how one of them ends up without it.
///
/// Quiet on purpose: secondary colour, smallest type. It has to be legible,
/// not prominent — a loud credit under every chart would compete with the
/// reading it belongs to.
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
        child: Text(
          context.l10n.weatherAttribution,
          style: AppTextStyle.bodySmall.copyWith(
            color: AppColors.textSecondary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
