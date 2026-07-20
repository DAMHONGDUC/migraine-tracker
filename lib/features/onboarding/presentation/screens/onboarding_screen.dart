import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../providers.dart';

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
      if (context.mounted) context.goNamed(AppRoutes.log.name);
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
                AppSpacingConstant.h24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: switch (page.value) {
                  0 => [
                    AppButton.primary(
                      onPressed: next,
                      label: l10n.onboardingContinue,
                    ),
                  ],
                  1 => [
                    AppButton.primary(
                      onPressed: () async {
                        await controller.requestLocation();
                        await next();
                      },
                      label: l10n.onboardingLocationAllow,
                    ),
                    SizedBox(height: AppSpacingConstant.h8),
                    AppButton.text(
                      onPressed: next,
                      label: l10n.onboardingNotNow,
                    ),
                  ],
                  _ => [
                    AppButton.primary(
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

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({
    required this.icon,
    required this.title,
    required this.body,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacingConstant.w24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppSpacingConstant.r64,
            color: context.colorScheme.primary,
          ),
          SizedBox(height: AppSpacingConstant.h24),
          Text(
            title,
            style: AppTextStyle.headlineMedium.w600,
          ),
          SizedBox(height: AppSpacingConstant.h12),
          Text(
            body,
            style: AppTextStyle.bodyLarge.secondary,
          ),
          if (footer != null) ...[
            SizedBox(height: AppSpacingConstant.h24),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      icon: Icons.storm_outlined,
      title: l10n.onboardingWelcomeTitle,
      body: l10n.onboardingWelcomeBody,
      footer: Container(
        padding: EdgeInsets.all(AppSpacingConstant.w16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacingConstant.r12),
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: AppSpacingConstant.r20,
              color: context.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: AppSpacingConstant.w12),
            Expanded(
              child: Text(
                l10n.onboardingDisclaimer,
                style: AppTextStyle.bodySmall.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPage extends StatelessWidget {
  const _LocationPage({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      icon: Icons.location_on_outlined,
      title: l10n.onboardingLocationTitle,
      body: l10n.onboardingLocationBody,
    );
  }
}

class _ThresholdPage extends StatelessWidget {
  const _ThresholdPage({required this.l10n, required this.threshold});

  final AppLocalizations l10n;
  final ValueNotifier<double> threshold;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      icon: Icons.compress,
      title: l10n.onboardingThresholdTitle,
      body: l10n.onboardingThresholdBody,
      footer: ValueListenableBuilder<double>(
        valueListenable: threshold,
        builder: (context, value, _) => Column(
          children: [
            Text(
              l10n.onboardingThresholdValue(value.round()),
              style: AppTextStyle.displaySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.primary,
              ),
            ),
            Slider(
              value: value,
              min: 3,
              max: 10,
              divisions: 7,
              onChanged: (v) => threshold.value = v,
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < OnboardingScreen._pageCount; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            margin: EdgeInsets.symmetric(horizontal: AppSpacingConstant.w4),
            width: i == current ? AppSpacingConstant.w20 : AppSpacingConstant.w8,
            height: AppSpacingConstant.h8,
            decoration: BoxDecoration(
              color: i == current
                  ? context.colorScheme.primary
                  : context.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacingConstant.r4),
            ),
          ),
      ],
    );
  }
}
