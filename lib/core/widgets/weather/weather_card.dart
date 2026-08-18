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

  /// Only the live caller can be loading; a stored snapshot is already here
  /// or is not. A spinner rather than [emptyLabel] while the first fetch is
  /// in flight, because "unavailable" for the length of a round trip told
  /// every user the feature was broken.
  final bool isLoading;

  Future<void> _openDetail(BuildContext context, WeatherCardData weather) {
    SdLogger.action(LogTagConstant.weatherCard, 'Weather detail', title);

    return WeatherDetailSheet(title: title, data: weather).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WeatherCardData? weather = data?.isEmpty ?? true ? null : data;

    return SdCardV2(
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
/// It holds the headline's own height either way, so the card does not jump
/// a line's worth of height when the first fetch lands.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label, required this.isLoading});

  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SdSpacingConstant.h40,
      width: double.infinity,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(label, style: AppTextStyle.bodyMedium.secondary),
            ),
    );
  }
}
