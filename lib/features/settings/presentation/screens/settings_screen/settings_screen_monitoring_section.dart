part of 'settings_screen.dart';

/// The five rows about what the app watches, what it asks for, and where it shows it: pressure, activity, sleep, the evening check-in nudge, and the home screen widget.
class _MonitoringSection extends StatelessWidget {
  const _MonitoringSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        AlertsSettingsTile(),
        ActivitySettingsTile(),
        SleepSettingsTile(),
        // Above the widget row because it is the only one here that asks the user for something, rather than reading a source.
        CheckInReminderTile(),
        HomeWidgetSettingsTile(),
      ],
    );
  }
}
