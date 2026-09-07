import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/app_feature_list.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../app_config/domain/entities/installed_app_version.dart';
import '../../../../app_config/providers.dart';
import '../../../domain/services/app_version_label.dart';

part 'about_screen_header.dart';

/// What the app is and everything it does, in one screen.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return SdScaffoldV2(
      title: Text(l10n.aboutTitle, style: AppTextStyle.titleLarge),
      body: ListView(
        padding: SdContentPaddingV2.screen(context),
        children: <Widget>[
          const _AboutHeader(),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          const AppFeatureList(),
          SizedBox(height: SdSpacingConstant.h8),
          // Hard rule 11: the app never promises diagnosis or treatment, and the screen that lists what it does is where that has to be said.
          Text(
            l10n.onboardingDisclaimer,
            style: AppTextStyle.bodySmall.secondary,
          ),
        ],
      ),
    );
  }
}
