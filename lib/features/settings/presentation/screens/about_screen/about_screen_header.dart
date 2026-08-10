part of 'about_screen.dart';

/// Name, one line on what the app is for, and the build it is.
///
/// The version sits here rather than at the bottom because this screen is
/// also where someone goes to answer "which build am I on" — Settings' own
/// row carries the same string for the same reason.
class _AboutHeader extends ConsumerWidget {
  const _AboutHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final InstalledAppVersion? version = ref
        .watch(installedAppVersionProvider)
        .value;

    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.appTitle, style: AppTextStyle.titleLarge),
            SizedBox(height: SdSpacingConstant.h4),
            Text(l10n.aboutTagline, style: AppTextStyle.bodyMedium.secondary),
            SizedBox(height: SdSpacingConstant.h16),
            const SdDividerV2(),
            SizedBox(height: SdSpacingConstant.h16),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.aboutVersionLabel,
                    style: AppTextStyle.bodyMedium,
                  ),
                ),
                Text(
                  AppVersionLabel.build(version),
                  style: AppTextStyle.bodyMedium.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
