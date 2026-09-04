import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/log_tag_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/services/link_launcher_provider.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/app_feature_list.dart';
import '../../../../../core/widgets/premium_gate.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../providers.dart';

part 'subscription_screen_manage_button.dart';
part 'subscription_screen_status_card.dart';

/// What the subscription is right now, and what it includes.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool premium = ref.watch(hasPremiumProvider);

    return SdScaffoldV2(
      title: Text(l10n.premiumScreenTitle, style: AppTextStyle.titleLarge),
      body: SdActionViewV2(
        // Pinned, not scrolling: the list below is every feature the app has, so an action travelling with it is one the user has to go looking for.
        placement: SdActionsPlacementV2.pinned,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _StatusCard(premium: premium),
            SizedBox(height: SdSpacingConstant.h24),
            // The same list About and onboarding draw. It was five hand-picked paywall benefits, which said what Premium adds and never what the free
            // plan already covers — the one question someone on this screen is asking. One widget, so the three surfaces cannot drift apart.
            const AppFeatureList(),
          ],
        ),
        actions: <Widget>[
          if (premium) ...<Widget>[
            const _ManageButton(),
            // The note stays under the button: cancelling and refunds happen on the store's page, not here, and the button only opens it.
            Text(
              l10n.premiumScreenManageNote,
              style: AppTextStyle.bodySmall.secondary,
            ),
          ] else
            SdButtonV2(
              variant: SdButtonVariantV2.primary,
              onPressed: () => NavigationUtils.toPaywall(context, ref),
              label: l10n.premiumUnlock,
            ),
        ],
      ),
    );
  }
}
