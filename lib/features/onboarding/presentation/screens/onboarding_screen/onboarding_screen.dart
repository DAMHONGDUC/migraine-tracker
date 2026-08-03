import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../providers.dart';
import '../../widgets/onboarding_features_sheet.dart';

part 'onboarding_screen_dots.dart';
part 'onboarding_screen_location_page.dart';
part 'onboarding_screen_page_scaffold.dart';
part 'onboarding_screen_threshold_page.dart';
part 'onboarding_screen_welcome_page.dart';

/// Three calm pages: welcome + medical disclaimer (hard rule 10), the location
/// permission explainer (hard rule 2), and threshold setup.
///
/// What the app does is not a page any more — the last step offers it as a
/// sheet, so the nine-row feature list is there for whoever asks and out of
/// the way of everyone else.
class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  static const _pageCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(onboardingControllerProvider);
    final pageController = usePageController();
    final page = useState(0);
    final threshold = useState<double>(5);

    Future<void> next() => pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );

    Future<void> finish() async {
      await controller.complete(thresholdHpa: threshold.value);
      if (context.mounted) context.goNamed(AppRoutes.dashboard.name);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: pageController,
                onPageChanged: (value) => page.value = value,
                children: [
                  _WelcomePage(l10n: l10n),
                  _LocationPage(l10n: l10n),
                  _ThresholdPage(l10n: l10n, threshold: threshold),
                ],
              ),
            ),
            _Dots(current: page.value),
            Padding(
              padding: EdgeInsets.fromLTRB(
                SdSpacingConstant.w24,
                SdSpacingConstant.h16,
                SdSpacingConstant.w24,
                // SafeArea already clears the home indicator; this is the gap.
                SdSpacingConstant.h16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: switch (page.value) {
                  // Welcome just moves on.
                  0 => [
                    SdButtonV2(
                      variant: SdButtonVariantV2.primary,
                      onPressed: next,
                      label: l10n.onboardingContinue,
                    ),
                  ],
                  1 => [
                    SdButtonV2(
                      variant: SdButtonVariantV2.primary,
                      onPressed: () async {
                        await controller.requestLocation();
                        await next();
                      },
                      label: l10n.onboardingLocationAllow,
                    ),
                    SizedBox(height: SdSpacingConstant.h8),
                    SdButtonV2(
                      variant: SdButtonVariantV2.outlined,
                      onPressed: next,
                      label: l10n.onboardingNotNow,
                    ),
                  ],
                  _ => [
                    SdButtonV2(
                      variant: SdButtonVariantV2.primary,
                      onPressed: finish,
                      label: l10n.onboardingStart,
                    ),
                    SizedBox(height: SdSpacingConstant.h8),
                    SdButtonV2(
                      variant: SdButtonVariantV2.outlined,
                      onPressed: () =>
                          const OnboardingFeaturesSheet().show(context),
                      label: l10n.onboardingFeaturesAction,
                    ),
                  ],
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
