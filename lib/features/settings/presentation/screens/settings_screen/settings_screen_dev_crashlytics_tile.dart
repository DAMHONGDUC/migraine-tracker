part of 'settings_screen.dart';

/// Dev-only: proves a build reports to Crashlytics — a non-fatal sent now, or a native crash sent on the next launch.
///
/// Exists because a prod crash was seen on a device with nothing in the
/// console, and "does this build report at all" was a question with no tool.
class _DevCrashlyticsTile extends StatefulWidget {
  const _DevCrashlyticsTile();

  @override
  State<_DevCrashlyticsTile> createState() => _DevCrashlyticsTileState();
}

/// The two tests the dialog offers; Cancel is null.
enum _CrashlyticsTest { nonFatal, crash }

class _DevCrashlyticsTileState extends State<_DevCrashlyticsTile> {
  bool _running = false;

  Future<void> _open() async {
    final AppLocalizations l10n = context.l10n;

    if (_running) return;

    SdLogger.info(LogTagConstant.settings, 'Crashlytics test opened', {
      'ready': CrashReporter.isReady,
      'collectionEnabled': CrashReporter.isCollectionEnabled,
    });

    final _CrashlyticsTest? picked = await showSdDialogV2<_CrashlyticsTest>(
      context,
      builder: (BuildContext dialogContext) => SdDialogV2(
        title: l10n.settingsDevCrashlytics,
        content: Text(
          // The state first: a debug build starts with collection off, which is the first thing a "nothing arrived" asks.
          '${CrashReporter.isCollectionEnabled ? l10n.settingsDevCrashlyticsCollectionOn : l10n.settingsDevCrashlyticsCollectionOff}\n\n'
          '${l10n.settingsDevCrashlyticsBody}',
          style: AppTextStyle.bodyMedium,
        ),
        actions: <Widget>[
          SdButtonV2(
            variant: SdButtonVariantV2.text,
            onPressed: () => Navigator.of(dialogContext).pop(),
            label: l10n.commonCancel,
          ),
          SdButtonV2(
            variant: SdButtonVariantV2.secondary,
            onPressed: () =>
                Navigator.of(dialogContext).pop(_CrashlyticsTest.nonFatal),
            label: l10n.settingsDevCrashlyticsNonFatal,
          ),
          SdButtonV2(
            variant: SdButtonVariantV2.destructive,
            onPressed: () =>
                Navigator.of(dialogContext).pop(_CrashlyticsTest.crash),
            label: l10n.settingsDevCrashlyticsCrash,
          ),
        ],
      ),
    );

    if (picked == null || !mounted) return;

    setState(() => _running = true);
    try {
      switch (picked) {
        case _CrashlyticsTest.nonFatal:
          SdLogger.info(LogTagConstant.settings, 'Crashlytics test non-fatal');
          await CrashReporter.sendTestError();
          SdLogger.info(LogTagConstant.settings, 'Crashlytics test sent');
          if (mounted) {
            SdSnackBarUtilsV2.info(context, l10n.settingsDevCrashlyticsSent);
          }
        case _CrashlyticsTest.crash:
          // Logged before, because nothing runs after.
          SdLogger.info(LogTagConstant.settings, 'Crashlytics test crash');
          await CrashReporter.crashForTest();
      }
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.settings,
        'Crashlytics test failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        SdSnackBarUtilsV2.error(
          context,
          l10n.settingsDevCrashlyticsFailed('$error'),
        );
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: AppIconConstant.warning,
      iconColor: context.colorScheme.primary,
      title: context.l10n.settingsDevCrashlytics,
      trailing: _running
          ? SizedBox(
              width: SdSpacingConstant.r20,
              height: SdSpacingConstant.r20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _open,
    );
  }
}
