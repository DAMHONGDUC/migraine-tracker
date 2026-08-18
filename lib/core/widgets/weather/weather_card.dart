import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../features/weather/domain/entities/weather_report.dart';
import '../../../features/weather/domain/entities/weather_snapshot.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../constants/log_tag_constant.dart';
import '../../extensions/context_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import '../../utils/date_time_utils.dart';
import '../../utils/signed_number_utils.dart';
import 'weather_attribution.dart';

part 'weather_card_condition.dart';
part 'weather_card_data.dart';
part 'weather_card_headline.dart';
part 'weather_card_metrics.dart';
part 'weather_card_week.dart';
part 'weather_detail_sheet.dart';

/// One weather card, drawn the same way wherever weather appears.
///
/// **In `core/` rather than in a feature, because two features draw it** —
/// the dashboard shows the conditions the user is in right now, and an
/// attack's detail screen shows the ones it was logged in. A widget one
/// feature owned would have to be imported from another's `presentation/`,
/// which the dependency rule forbids; this is the same answer
/// `core/widgets/sections/` already gives for a shared section.
///
/// **Two lines, and no heading** (owner's call). The sky and the temperature
/// on one, the readings as bare glyphs and numbers on the next — that is the
/// whole card. It carried a title row first: a word the reading under it
/// already says, costing a line on a readout the user passes on the way
/// somewhere. [title] survives for the sheet, which does need naming.
///
/// **The whole card opens [WeatherDetailSheet], where every reading is named
/// in full** (owner's call). The chevron is a mark rather than a button: a
/// card-sized target is what a readout with nothing else to tap should have,
/// an icon button inside it would be a second and smaller way to do the same
/// thing, and the dashboard's own rule is that a card which opens something
/// wears a trailing chevron to say so.
///
/// **It draws, it does not fetch.** Both callers hand it a [WeatherCardData]
/// they built from their own source, so the card has no opinion on whether
/// the reading is live or hours old — see [CurrentWeatherCard] for the live
/// one.
///
/// **It is the one card in the app wearing a gradient** (owner's call), so
/// the weather reads as the screen's own subject rather than as one more
/// readout in a stack of identical panels. See [gradient] for what keeps it
/// inside hard rule 3.
///
/// **The Apple mark lives in the sheet, not on the card** (owner's call). It
/// is a required credit and it cost the card a whole line to say something no
/// user came for; the card is one tap from it, so the mark stays reachable
/// from every surface that draws Apple's data rather than being dropped. This
/// is the compact reading of WeatherKit's attribution rule — if App Review
/// ever objects, the answer is to put `WeatherAttribution` back on the card,
/// never to take it out of the sheet.
class WeatherCard extends StatelessWidget {
  const WeatherCard({
    required this.title,
    required this.data,
    required this.emptyLabel,
    this.place,
    this.isLoading = false,
    super.key,
  });

  /// Names the sheet, never the card. The two callers mean something
  /// different by it — "Weather" against "Weather at the time" — so it cannot
  /// be a constant inside the sheet either.
  final String title;

  /// Null, or empty, means there is nothing to draw and [emptyLabel] is shown
  /// instead.
  final WeatherCardData? data;

  /// What the card says with no data. The callers mean different things by it
  /// — "not fetched" against "never attached" — and one shared string would
  /// be wrong on one of them.
  final String emptyLabel;

  /// Where the reading is from — a ward, a district or a city, whichever the
  /// platform could name. Null on the attack card, whose stored snapshot has
  /// no coordinates to geocode, and null while the name is still being read.
  final String? place;

  /// Only the live caller can be loading; a stored snapshot is already here
  /// or is not. A spinner rather than [emptyLabel] while the first fetch is
  /// in flight, because "unavailable" for the length of a round trip told
  /// every user the feature was broken.
  final bool isLoading;

  /// A tint of the accent across the card, top-left to bottom-right.
  ///
  /// **Quiet, and it has to stay quiet.** The app's users are photophobic
  /// (hard rule 3), so this is one hue at low alpha over the card colour —
  /// never two saturated colours meeting, never a bright fill. The stops go
  /// 0.18 → 0.04 rather than to zero, so the far corner still reads as part
  /// of the same surface instead of fading into an edge.
  ///
  /// It does not change with the weather. A card that turned orange in the
  /// sun and grey in the rain would be a second, louder way of saying what
  /// the glyph already says, and it would be at its brightest exactly when
  /// the user's day is.
  static LinearGradient gradient(BuildContext context) => LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: <Color>[
      Color.alphaBlend(
        AppColors.primary.withValues(alpha: 0.18),
        context.colorScheme.surface,
      ),
      Color.alphaBlend(
        AppColors.primary.withValues(alpha: 0.04),
        context.colorScheme.surface,
      ),
    ],
  );

  Future<void> _openDetail(BuildContext context, WeatherCardData weather) {
    SdLogger.action(LogTagConstant.weatherCard, 'Weather detail', title);

    return WeatherDetailSheet(
      title: title,
      data: weather,
      place: place,
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WeatherCardData? weather = data?.isEmpty ?? true ? null : data;

    return SdCardV2(
      gradient: gradient(context),
      // **The tap and the chevron drop together where there is no reading.**
      // A mark that promises a screen must never sit above a tap that opens
      // an empty one.
      onTap: weather == null
          ? null
          : () => unawaited(_openDetail(context, weather)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdSpacingConstant.w16,
          vertical: SdSpacingConstant.h12,
        ),
        child: weather == null
            ? _Placeholder(label: emptyLabel, isLoading: isLoading)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // - the place arrives after the reading, so the card grows
                  //   by a line once rather than reserving one it may not fill
                  // - no skeleton for it either: a placeholder that resolves
                  //   to nothing is worse than a line that simply appears
                  if (place case final String name) ...<Widget>[
                    _PlaceLine(name: name),
                    SizedBox(height: SdSpacingConstant.h4),
                  ],
                  _Headline(
                    data: weather,
                    // Semantics carries what the glyph cannot say; the tap
                    // belongs to the card, so this is decoration.
                    trailing: Semantics(
                      label: l10n.weatherA11yDetail,
                      child: SdIconV2(
                        icon: Icons.chevron_right,
                        size: SdSpacingConstant.r20,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(height: SdSpacingConstant.h12),
                  _MetricStrip(metrics: _metrics(l10n, weather)),
                ],
              ),
      ),
    );
  }
}

/// What fills the card before there is a reading, or instead of one.
///
/// **Loading is a skeleton in the card's own shape, not a spinner.** The card
/// is a fixed two lines, so the placeholder can be exactly the size of what
/// is coming — which means the dashboard does not reflow under the user's
/// thumb when the fetch lands. A spinner would have said only "waiting", in a
/// box of some other height.
///
/// The unavailable state is still a sentence: that one is an answer, not a
/// wait, and a skeleton that never resolves is the worst of both.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label, required this.isLoading});

  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return SizedBox(
        height: SdSpacingConstant.h40,
        width: double.infinity,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(label, style: AppTextStyle.bodyMedium.secondary),
        ),
      );
    }

    // Every measurement is read from the real thing rather than guessed, so
    // the two cannot drift: the tile that holds the sky, and the tray that
    // holds the readings.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SdSkeletonV2(
              height: _ConditionTile.size,
              width: _ConditionTile.size,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // The temperature, then the shorter caption under it.
                  SdSkeletonV2.line(
                    fraction: 0.3,
                    height: SdSpacingConstant.h20,
                  ),
                  SizedBox(height: SdSkeletonV2.lineGap),
                  SdSkeletonV2.line(fraction: 0.65),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h12),
        SdSkeletonV2(height: _MetricStrip.height),
      ],
    );
  }
}
