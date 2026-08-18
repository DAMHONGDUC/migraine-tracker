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
///
/// **The logo is an icon, not a character.** The string used to carry U+F8FF,
/// which is Apple's logo only in Apple's own fonts — the app bundles Noto
/// Sans, so it drew a blank box and the mark read as " Weather". The word
/// comes from the ARB and the logo from `SimpleIcons.apple`, the same glyph
/// the Apple sign-in button uses.
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
