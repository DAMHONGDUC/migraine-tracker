part of 'weather_card.dart';

/// What the card's arrow opens: every reading named, and ten days of rain.
class WeatherDetailScreen extends StatefulWidget {
  const WeatherDetailScreen({required this.args, super.key});

  final WeatherDetailArgs args;

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

/// Everything the screen is opened with, in one object.
@immutable
class WeatherDetailArgs {
  const WeatherDetailArgs({
    required this.title,
    required this.data,
    this.place,
  });

  final String title;
  final WeatherCardData data;

  /// Where the reading is from. Null for an attack's stored snapshot, which never carried coordinates.
  final String? place;
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  /// Today, which is what the card the user came from was showing — the screen opens on the same reading rather than on a day they did not ask for.
  int _selected = 0;

  void _select(int index) {
    if (index == _selected) return;

    SdLogger.action(LogTagConstant.weatherCard, 'Weather day', index);
    setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WeatherDetailArgs args = widget.args;
    // Today is returned untouched, so day 0 keeps the live reading rather than being rebuilt from its own forecast.
    final WeatherCardData day = args.data.dayAt(_selected);

    return SdScaffoldV2(
      title: Text(args.title, style: AppTextStyle.titleLarge),
      body: Padding(
        // `SdScaffoldV2` deliberately pads nothing.
        padding: SdContentPaddingV2.screen(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // - the place on the left, Apple's mark on the right, one line.
            Row(
              children: <Widget>[
                if (args.place case final String name)
                  Flexible(child: _PlaceLine(name: name)),
                const Spacer(),
                const WeatherAttribution(),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h8),
            _Headline(data: day),
            SizedBox(height: SdSpacingConstant.h16),
            _MetricGrid(metrics: _metrics(l10n, day)),
            // - absent for an attack's snapshot,.
            if (args.data.days.isNotEmpty) ...<Widget>[
              SizedBox(height: SdSpacingConstant.h20),
              Expanded(
                child: _RainfallForecast(
                  days: args.data.days,
                  selected: _selected,
                  onSelected: _select,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
