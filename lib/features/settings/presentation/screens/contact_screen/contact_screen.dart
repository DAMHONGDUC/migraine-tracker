import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/env/app_env.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../app_update/domain/entities/installed_app_version.dart';
import '../../../../app_update/providers.dart';
import '../../../domain/services/app_version_label.dart';
import '../../../providers.dart';

/// Where a user reaches a human: the support inbox, shown, and a one-tap
/// way to open it. Pushed from Settings' About section.
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  Future<void> _emailSupport(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final InstalledAppVersion? version = ref
        .read(installedAppVersionProvider)
        .value;

    try {
      final bool opened = await ref
          .read(contactControllerProvider)
          .emailSupport(
            subject: l10n.contactSupportEmailSubject,
            body: 'App version: ${AppVersionLabel.build(version)}',
          );

      if (!context.mounted || opened) return;
      SdSnackBarUtilsV2.error(context, l10n.contactSupportEmailFailed);
    } catch (_) {
      // The controller already logged it; the user needs the outcome.
      if (context.mounted) {
        SdSnackBarUtilsV2.error(context, l10n.contactSupportEmailFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return SdScaffoldV2(
      title: Text(l10n.contactScreenTitle, style: AppTextStyle.titleLarge),
      body: SdActionViewV2(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.contactSupportIntro,
              style: AppTextStyle.bodyMedium.secondary,
            ),
            SizedBox(height: SdSpacingConstant.h16),
            SdCardV2(
              child: Padding(
                padding: EdgeInsets.all(SdSpacingConstant.w16),
                child: Row(
                  children: <Widget>[
                    const SdIconV2(icon: Icons.email_outlined),
                    SizedBox(width: SdSpacingConstant.w12),
                    Expanded(
                      child: Text(
                        AppEnv.supportEmail,
                        style: AppTextStyle.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          SdButtonV2(
            variant: SdButtonVariantV2.primary,
            icon: Icons.email_outlined,
            label: l10n.contactSupportEmailButton,
            onPressed: () => _emailSupport(context, ref),
          ),
        ],
      ),
    );
  }
}
