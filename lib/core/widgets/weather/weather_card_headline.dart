part of 'weather_card.dart';

/// The reading in one line: the sky, the temperature, what it feels like.
class _Headline extends StatelessWidget {
  const _Headline({required this.data, this.trailing});

  final WeatherCardData data;

  /// The card's chevron. Absent in the sheet, which is already open.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    // The live reading, or today's high and low.
    final String? temperature =
        WeatherConditionUtils.temperature(l10n, data.temperatureCelsius) ??
        _range(l10n);
    final String? caption = _caption(l10n);

    return Row(
      children: <Widget>[
        if (data.condition != null) ...<Widget>[
          _ConditionTile(condition: data.condition, daylight: data.daylight),
          SizedBox(width: SdSpacingConstant.w12),
        ],
        // `Expanded` either way, so the trailing chevron sits on the card's edge whether or not Apple sent a condition to draw a tile from.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (temperature != null)
                Text(
                  temperature,
                  style: AppTextStyle.headlineMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              // Two lines keep long localized conditions readable.
              if (caption != null)
                Text(
                  caption,
                  style: AppTextStyle.bodySmall.secondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (trailing case final Widget widget) ...<Widget>[
          SizedBox(width: SdSpacingConstant.w8),
          widget,
        ],
      ],
    );
  }

  /// Today's low and high, or null unless the report carried both ends of a day. Half a range is a number the reader cannot place.
  String? _range(AppLocalizations l10n) {
    final String? low = WeatherConditionUtils.temperature(
      l10n,
      data.forecast?.temperatureMinCelsius,
    );
    final String? high = WeatherConditionUtils.temperature(
      l10n,
      data.forecast?.temperatureMaxCelsius,
    );

    if (low == null || high == null) return null;

    return l10n.weatherRange(low, high);
  }

  /// The condition word, and what it feels like when Apple said so.
  String? _caption(AppLocalizations l10n) {
    final String? label = WeatherConditionUtils.label(
      l10n,
      data.condition ?? data.forecast?.condition,
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

/// The sky, in a tinted square.
class _ConditionTile extends StatelessWidget {
  const _ConditionTile({required this.condition, required this.daylight});

  final WeatherCondition? condition;
  final bool? daylight;

  /// The tile is square, and this is both of its sides. Read by the loading skeleton too, so the placeholder is the size of what replaces it.
  static double get size => SdSpacingConstant.w44;

  static const double tint = 0.14;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: tint),
        borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: SdIconV2(
            icon: WeatherConditionUtils.icon(condition, daylight: daylight),
            size: AppIconSize.medium,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Where the reading is from, in one line above it.
class _PlaceLine extends StatelessWidget {
  const _PlaceLine({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // The glyph is a pin and says nothing out loud; the label is what carries "this is a place" to a screen reader.
      label: context.l10n.weatherA11yPlace(name),
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            SdIconV2(
              icon: AppIconConstant.location,
              size: AppIconSize.xSmall,
              color: context.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: SdSpacingConstant.w4),
            Flexible(
              child: Text(
                name,
                style: AppTextStyle.bodySmall.secondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
