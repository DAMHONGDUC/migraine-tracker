part of 'attack_detail_screen.dart';

class _WeatherSection extends StatelessWidget {
  const _WeatherSection({required this.attack});

  final Attack attack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weather = attack.weather;

    if (weather == null) {
      return _Section(
        title: l10n.attackDetailWeatherTitle,
        children: [
          ListTile(
            leading: AppIcon(
              Icons.cloud_off,
              color: context.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              l10n.attackDetailNoWeather,
              style: AppTextStyle.bodyMedium.secondary,
            ),
          ),
        ],
      );
    }

    final delta = weather.pressureDelta24hHpa;
    return _Section(
      title: l10n.attackDetailWeatherTitle,
      children: [
        _ReadOnlyRow(
          label: l10n.attackDetailPressure,
          value: l10n.attackDetailPressureValue(
            weather.pressureHpa.toStringAsFixed(1),
          ),
        ),
        ListTile(
          title: Text(l10n.attackDetailPressureDelta),
          trailing: Text(
            l10n.attackDetailPressureValue(
              '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
            ),
            style: AppTextStyle.bodyLarge.copyWith(
              // A drop is what this app is about — mark it.
              color: delta <= -5 ? AppColors.error : null,
              fontWeight: delta <= -5 ? FontWeight.w600 : null,
            ),
          ),
        ),
        if (weather.humidityPercent != null)
          _ReadOnlyRow(
            label: l10n.attackDetailHumidity,
            value: l10n.attackDetailHumidityValue(
              weather.humidityPercent!.toStringAsFixed(0),
            ),
          ),
        if (weather.temperatureCelsius != null)
          _ReadOnlyRow(
            label: l10n.attackDetailTemperature,
            value: l10n.attackDetailTemperatureValue(
              weather.temperatureCelsius!.toStringAsFixed(1),
            ),
          ),
      ],
    );
  }
}

