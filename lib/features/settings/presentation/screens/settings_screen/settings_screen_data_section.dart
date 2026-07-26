part of 'settings_screen.dart';

/// Get the data out, or destroy it. Export is free forever (hard rule 8);
/// the doctor report is its premium flavour.
class _DataSection extends ConsumerWidget {
  const _DataSection();

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final ExportFormat? format = await const ExportFormatSheet().show(context);

    if (format == null) return;

    await ref.read(settingsControllerProvider).export(format);
  }

  Future<void> _shareDoctorReport(BuildContext context, WidgetRef ref) async {
    // Localized: the bundled Noto Sans font covers Vietnamese.
    final l10n = context.l10n;
    final strings = DoctorReportStrings(
      title: l10n.reportTitle,
      generated: l10n.reportGenerated(
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
      ),
      period: l10n.reportPeriod,
      summaryTitle: l10n.reportSummaryTitle,
      totalAttacks: l10n.reportTotalAttacks,
      avgIntensity: l10n.reportAvgIntensity,
      commonLocation: l10n.reportCommonLocation,
      attacksDuringDrops: l10n.reportAttacksDuringDrops,
      tableTitle: l10n.reportTableTitle,
      colDate: l10n.reportColDate,
      colIntensity: l10n.reportColIntensity,
      colLocation: l10n.reportColLocation,
      colMedication: l10n.reportColMedication,
      colPressureDelta: l10n.reportColPressureDelta,
      disclaimer: l10n.onboardingDisclaimer,
      locationLabels: {
        for (final location in HeadLocation.values)
          location: location.label(l10n),
      },
    );

    await ref.read(settingsControllerProvider).shareDoctorReport(strings);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      children: [
        ListTile(
          leading: const AppIcon(Icons.ios_share),
          title: Text(l10n.settingsExport, style: AppTextStyle.bodyLarge),
          onTap: () => _export(context, ref),
        ),
        PremiumTileGate(
          icon: Icons.picture_as_pdf_outlined,
          title: l10n.settingsDoctorReport,
          lockedMessage: l10n.premiumLockedReport,
          child: ListTile(
            leading: const AppIcon(Icons.picture_as_pdf_outlined),
            title: Text(
              l10n.settingsDoctorReport,
              style: AppTextStyle.bodyLarge,
            ),
            onTap: () => _shareDoctorReport(context, ref),
          ),
        ),
        const _DeleteAllTile(),
      ],
    );
  }
}
