part of 'attack_detail_screen.dart';

/// The weather this attack was logged in, drawn by the same [WeatherCard] the dashboard uses for the weather right now.
class _WeatherSection extends StatelessWidget {
  const _WeatherSection({required this.attack});

  final Attack attack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weather = attack.weather;

    return WeatherCard(
      title: l10n.attackDetailWeatherTitle,
      data: weather == null ? null : WeatherCardData.ofSnapshot(weather),
      // Not the live card's "unavailable": this attack was logged offline and the backfill has not caught it yet, which is a different answer.
      emptyLabel: l10n.attackDetailNoWeather,
    );
  }
}
