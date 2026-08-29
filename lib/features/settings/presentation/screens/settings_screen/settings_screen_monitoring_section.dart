part of 'settings_screen.dart';

/// The four rows that are about what the app watches and where it shows it: pressure, activity, sleep, and the home screen widget.
class _MonitoringSection extends StatelessWidget {
  const _MonitoringSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        AlertsSettingsTile(),
        ActivitySettingsTile(),
        SleepSettingsTile(),
        HomeWidgetSettingsTile(),
      ],
    );
  }
}
