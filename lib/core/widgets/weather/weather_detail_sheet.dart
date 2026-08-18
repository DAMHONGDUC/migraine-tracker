part of 'weather_card.dart';

/// Every reading the card had room only to hint at, each one named.
///
/// **The card's arrow opens this, and it is read-only** — no commit button
/// (`SdSheetContentV2` hides the slot when `onConfirm` is null), because there
/// is nothing here to answer.
///
/// **It is more than the card showed, not the same thing larger.** The card's
/// four glyphs become every reading, named; pressure, the chance of rain and
/// the sun's hours appear, having fallen past what the card has room for; and
/// the week ahead is drawn under them. That last one is why the sheet exists
/// at all — a seven-day forecast was the half of the retired Insights weather
/// card worth keeping, and it never fitted on a dashboard card.
///
/// **A day in that week can be tapped, and everything above it follows**
/// (owner's call). The headline becomes that day's high and low, and every
/// reading in the grid is re-read against it — the wind, the UV, the sun's
/// hours, the pressure. `WeatherCardData.dayAt` is where that assembly lives;
/// this only holds which day was picked.
///
/// **It takes the card's own [title]**, not a string of its own: the sheet is
/// the card opened up, so "Weather" and "Weather at the time" have to reach
/// it rather than be restated and drift.
///
/// A part of `weather_card.dart` because it draws the card's own `_Headline`
/// and `_MetricGrid` — one library, so the two surfaces cannot come to
/// disagree about what a reading is called or how it is rounded.
class WeatherDetailSheet extends StatefulWidget {
  const WeatherDetailSheet({
    required this.title,
    required this.data,
    super.key,
  });

  final String title;
  final WeatherCardData data;

  @override
  State<WeatherDetailSheet> createState() => _WeatherDetailSheetState();
}

class _WeatherDetailSheetState extends State<WeatherDetailSheet> {
  /// Today, which is what the card the user came from was showing — the sheet
  /// opens on the same reading rather than on a day they did not ask for.
  int _selected = 0;

  void _select(int index) {
    if (index == _selected) return;

    SdLogger.action(LogTagConstant.weatherCard, 'Weather day', index);
    setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    // Today is returned untouched, so day 0 keeps the live reading rather
    // than being rebuilt from its own forecast.
    final WeatherCardData day = widget.data.dayAt(_selected);

    return SdSheetContentV2(
      title: widget.title,
      closeTooltip: l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Headline(data: day),
          SizedBox(height: SdSpacingConstant.h16),
          _MetricGrid(metrics: _metrics(l10n, day)),
          // Absent for an attack's snapshot, which never stored a forecast.
          if (widget.data.days.isNotEmpty) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h20),
            _WeekForecast(
              days: widget.data.days,
              selected: _selected,
              onSelected: _select,
            ),
          ],
          SizedBox(height: SdSpacingConstant.h12),
          // Its own copy: the sheet covers the card that drew the other one,
          // and WeatherKit's mark has to be on the surface being looked at.
          const WeatherAttribution(),
        ],
      ),
    );
  }
}

extension WeatherDetailSheetExt on WeatherDetailSheet {
  Future<void> show(BuildContext context) => showSdBottomSheetV2<void>(
    context,
    // Without it the sheet route caps itself around half the screen and
    // `SdSheetContentV2`'s own ceiling never applies.
    isScrollControlled: true,
    builder: (_) => this,
  );
}
