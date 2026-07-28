import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_content_padding.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/app_value_slider.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../providers.dart';

part 'onboarding_screen_dots.dart';
part 'onboarding_screen_location_page.dart';
part 'onboarding_screen_page_scaffold.dart';
part 'onboarding_screen_threshold_page.dart';
part 'onboarding_screen_welcome_page.dart';

/// Three calm pages: welcome + medical disclaimer (hard rule 10), the
/// location permission explainer (hard rule 2), and threshold setup.
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
                AppSpacingConstant.w24,
                AppSpacingConstant.h16,
                AppSpacingConstant.w24,
                // SafeArea already clears the home indicator; this is the gap.
                AppSpacingConstant.h16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: switch (page.value) {
                  0 => [
                    AppButton(
                      variant: AppButtonVariant.primary,
                      onPressed: next,
                      label: l10n.onboardingContinue,
                    ),
                  ],
                  1 => [
                    AppButton(
                      variant: AppButtonVariant.primary,
                      onPressed: () async {
                        await controller.requestLocation();
                        await next();
                      },
                      label: l10n.onboardingLocationAllow,
                    ),
                    SizedBox(height: AppSpacingConstant.h8),
                    AppButton(
                      variant: AppButtonVariant.text,
                      onPressed: next,
                      label: l10n.onboardingNotNow,
                    ),
                  ],
                  _ => [
                    AppButton(
                      variant: AppButtonVariant.primary,
                      onPressed: finish,
                      label: l10n.onboardingStart,
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
