part of 'weather_card.dart';

/// The reading in one line: the sky, the temperature, what it feels like.
///
/// Shared by the card and the sheet, so the number a user glances at and the
/// one they open are the same line of type rather than two that drifted.
///
/// **One row, not a stack.** The temperature used to sit above its caption,
/// which cost the card a line for text the glyph beside it already implies;
/// side by side, the row is only as tall as the glyph and the caption takes
/// the width that is left.
///
/// **The glyph is drawn only where there is a condition to draw.** A stored
/// snapshot carries no condition code, and the "unknown" glyph beside a real
/// temperature reads as a failed load rather than as a reading Apple never
/// recorded.
class _Headline extends StatelessWidget {
  const _Headline({required this.data, this.trailing});

  final WeatherCardData data;

  /// The card's chevron. Absent in the sheet, which is already open.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    // The live reading, or today's high and low where Apple sent a forecast
    // but nothing for right now — a card with a week behind it must not come
    // up blank at the top.
    final String? temperature =
        WeatherConditionUtils.temperature(l10n, data.temperatureCelsius) ??
        _range(l10n);
    final String? caption = _caption(l10n);

    return Row(
      children: <Widget>[
        if (data.condition != null) ...<Widget>[
          SdIconV2(
            icon: WeatherConditionUtils.icon(
              data.condition,
              daylight: data.daylight,
            ),
            size: SdSpacingConstant.r36,
            color: AppColors.primary,
          ),
          SizedBox(width: SdSpacingConstant.w12),
        ],
        if (temperature != null) ...<Widget>[
          Text(
            temperature,
            style: AppTextStyle.headlineSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(width: SdSpacingConstant.w8),
        ],
        // Two lines rather than an ellipsis: the condition and what it feels
        // like are both the point, and a Vietnamese pair of them does not fit
        // one line beside the temperature. `Expanded` either way, so the
        // trailing chevron sits on the card's edge whether or not Apple sent
        // a condition to caption it with.
        Expanded(
          child: caption == null
              ? const SizedBox.shrink()
              : Text(
                  caption,
                  style: AppTextStyle.bodySmall.secondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        if (trailing case final Widget widget) ...<Widget>[
          SizedBox(width: SdSpacingConstant.w8),
          widget,
        ],
      ],
    );
  }

  /// Today's low and high, or null unless the report carried both ends of a
  /// day. Half a range is a number the reader cannot place.
  String? _range(AppLocalizations l10n) {
    final String? low = WeatherConditionUtils.temperature(
      l10n,
      data.today?.temperatureMinCelsius,
    );
    final String? high = WeatherConditionUtils.temperature(
      l10n,
      data.today?.temperatureMaxCelsius,
    );

    if (low == null || high == null) return null;

    return l10n.weatherRange(low, high);
  }

  /// The condition word, and what it feels like when Apple said so.
  String? _caption(AppLocalizations l10n) {
    final String? label = WeatherConditionUtils.label(
      l10n,
      data.condition ?? data.today?.condition,
    );
    final String? apparent = WeatherConditionUtils.temperature(
      l10n,
      data.apparentTemperatureCelsius,
    );

    if (apparent == null) return label;

    final String feels = l10n.weatherFeelsLike(apparent);

    return label == null ? feels : '$label · $feels';
  }
}
