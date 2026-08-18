part of 'weather_card.dart';

/// Every reading the card had room only to hint at, each one named.
///
/// **The card's arrow opens this, and it is read-only** — no commit button
/// (`SdSheetContentV2` hides the slot when `onConfirm` is null), because there
/// is nothing here to answer. It is the same data the card drew, at the size
/// that lets it carry labels.
///
/// **It takes the card's own [title]**, not a string of its own: the sheet is
/// the card opened up, so "Weather" and "Weather at the time" have to reach
/// it rather than be restated and drift.
///
/// A part of `weather_card.dart` because it draws the card's own `_Headline`
/// and `_MetricGrid` — one library, so the two surfaces cannot come to
/// disagree about what a reading is called or how it is rounded.
class WeatherDetailSheet extends StatelessWidget {
  const WeatherDetailSheet({
    required this.title,
    required this.data,
    super.key,
  });

  final String title;
  final WeatherCardData data;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SdSheetContentV2(
      title: title,
      closeTooltip: l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Headline(data: data),
          SizedBox(height: SdSpacingConstant.h16),
          _MetricGrid(metrics: _metrics(l10n, data)),
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
