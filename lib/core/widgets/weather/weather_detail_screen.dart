part of 'weather_card.dart';

/// What the card's arrow opens: every reading named, and ten days of rain.
///
/// **A screen, not a sheet** (owner's call). It was an `SdSheetContentV2`
/// under a ceiling of 85% of the display, and the content outgrew it: ten
/// named readings are five rows of grid, and ten days are ten rows.
///
/// **The page itself never scrolls** (owner's call). Everything above the
/// forecast — where the reading is from, the temperature, every named
/// reading — is on screen at once and stays there; only the ten days move,
/// inside their own box. A page that scrolled as one meant reaching the last
/// day put the temperature off the top, and the reading the user came for
/// was the first thing to leave.
///
/// **It is more than the card showed, not the same thing larger.** The card's
/// four glyphs become every reading, named; how much rain, wind, UV and the
/// sun's hours appear, having fallen past what the card has room for; and the
/// ten days of rainfall are drawn under them. That last one is why this
/// screen exists at all — a multi-day forecast was the half of the retired
/// Insights weather card worth keeping, and it never fitted on a card.
///
/// **A day in that list can be tapped, and everything above it follows**
/// (owner's call). The headline becomes that day's high and low, and every
/// reading in the grid is re-read against it — the wind, the UV, the sun's
/// hours, the pressure. `WeatherCardData.dayAt` is where that assembly lives;
/// this only holds which day was picked.
///
/// **It takes the card's own [title]**, not a string of its own: this is the
/// card opened up, so "Weather" and "Weather at the time" have to reach it
/// rather than be restated and drift.
///
/// A part of `weather_card.dart` because it draws the card's own `_Headline`
/// and `_MetricGrid` — one library, so the two surfaces cannot come to
/// disagree about what a reading is called or how it is rounded. That is also
/// why it sits in `core/widgets/` rather than under a feature: two features
/// open it, the dashboard's live card and an attack's stored one, and the
/// router reaches it by route name either way.
class WeatherDetailScreen extends StatefulWidget {
  const WeatherDetailScreen({required this.args, super.key});

  final WeatherDetailArgs args;

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

/// Everything the screen is opened with, in one object.
///
/// **Passed as the route's `extra`, not fetched again here.** The card has
/// already read the report and the place name; re-reading them behind a push
/// would mean the screen could disagree with the card the user tapped, and
/// would cost a second geocode for a name already on screen.
@immutable
class WeatherDetailArgs {
  const WeatherDetailArgs({required this.title, required this.data, this.place});

  final String title;
  final WeatherCardData data;

  /// Where the reading is from. Null for an attack's stored snapshot, which
  /// never carried coordinates.
  final String? place;
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  /// Today, which is what the card the user came from was showing — the
  /// screen opens on the same reading rather than on a day they did not ask
  /// for.
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
    // Today is returned untouched, so day 0 keeps the live reading rather
    // than being rebuilt from its own forecast.
    final WeatherCardData day = args.data.dayAt(_selected);

    return SdScaffoldV2(
      title: Text(args.title, style: AppTextStyle.titleLarge),
      body: Padding(
        // `SdScaffoldV2` deliberately pads nothing — the body flows behind the
        // glass bar, so the screen owes its own top inset or the first line
        // sits under the title.
        padding: SdContentPaddingV2.screen(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // - the place on the left, Apple's mark on the right, one line
            // - the mark is a required credit, and it reads as one up here
            //   rather than as a footnote at the end of a long page
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
            // - absent for an attack's snapshot, which stored no forecast
            // - Expanded: it takes whatever the readings above left, and the
            //   days that do not fit scroll inside it rather than moving them
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
