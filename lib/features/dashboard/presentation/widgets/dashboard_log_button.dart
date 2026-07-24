import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../attacks/providers.dart';

/// The dashboard's hero call-to-action: a big, unmissable button that opens
/// the sacred 3-tap log flow (now a pushed route rather than a tab). Resets
/// any stale flow state before pushing so it always starts fresh at
/// intensity.
class DashboardLogButton extends ConsumerWidget {
  const DashboardLogButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSpacingConstant.h108,
          child: AppButton.primary(
            icon: Icons.add,
            label: l10n.dashboardLogButton,
            labelStyle: AppTextStyle.titleLarge.w600,
            onPressed: () {
              ref.read(logControllerProvider.notifier).reset();
              context.pushNamed(AppRoutes.log.name);
            },
          ),
        ),
        SizedBox(height: AppSpacingConstant.h8),
        Text(
          l10n.dashboardLogButtonSubtitle,
          textAlign: TextAlign.center,
          style: AppTextStyle.bodySmall.secondary,
        ),
      ],
    );
  }
}
