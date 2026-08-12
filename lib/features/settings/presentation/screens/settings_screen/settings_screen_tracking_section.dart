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
class _TrackingSection extends StatelessWidget {
  const _TrackingSection();

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
