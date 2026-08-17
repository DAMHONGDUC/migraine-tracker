part of 'settings_screen.dart';

/// The four rows that are about what the app watches and where it shows it:
/// pressure, activity, sleep, and the home screen widget.
///
/// They sat in [_GeneralSection] with the account and the language, which
/// made that group a list of unrelated things — a sign-in row, then three
/// insight screens, then a widget switch. These four each open a surface
/// with its own switches, so they read as one subject and now sit as one.
///
/// Pressure leads: it is the app's own subject. The widget is last — it is
/// where the others get shown, not another thing being watched.
///
/// **The heading is "Monitoring", and it must not go back to "Tracking".**
/// Owner's call, taken after submission 1.0(11) came back under 5.1.2(i) for
/// privacy labels claiming tracking the app does not do. On the App Store
/// that word means one specific thing — following a user across other
/// companies' apps for advertising — and this section is the opposite of it:
/// the app watching a barometer and this device's own health data, on the
/// user's behalf. Same meaning, without a reviewer having to decide which
/// sense was intended.
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
