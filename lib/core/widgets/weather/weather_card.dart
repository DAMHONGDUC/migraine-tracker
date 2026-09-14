import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../features/weather/domain/entities/weather_report.dart';
import '../../../features/weather/domain/entities/weather_snapshot.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../constants/log_tag_constant.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icon_constant.dart';
import '../../theme/app_icon_size.dart';
import '../../theme/app_text_style.dart';
import '../../utils/date_time_utils.dart';
import '../../utils/signed_number_utils.dart';
import 'weather_attribution.dart';

part 'weather_card_condition.dart';
part 'weather_card_data.dart';
part 'weather_card_headline.dart';
part 'weather_card_metrics.dart';
part 'weather_card_rainfall.dart';
part 'weather_detail_screen.dart';

/// One weather card, drawn the same way wherever weather appears.
class WeatherCard extends StatelessWidget {
  const WeatherCard({
    required this.title,
    required this.data,
    required this.emptyLabel,
    this.place,
    this.isLoading = false,
    this.onRetry,
    super.key,
  });

  /// Names the sheet, never the card.
  final String title;

  /// Null, or empty, means there is nothing to draw and [emptyLabel] is shown instead.
  final WeatherCardData? data;

  /// What the card says with no data.
  final String emptyLabel;

  /// Where the reading is from — a ward, a district or a city, whichever the platform could name.
  final String? place;

  /// Only the live caller can be loading; a stored snapshot is already here or is not.
  final bool isLoading;

  /// Runs the read again from the empty state. Null on a stored snapshot — there is nothing to re-fetch for an attack logged offline, the backfill owns that.
  final VoidCallback? onRetry;

  /// A tint of the accent across the card, top-left to bottom-right.
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

    // By route name with the reading as `extra`: the screen lives in this library but nothing outside the router should have to import it.
    return context.pushNamed<void>(
      AppRoutes.weather.name,
      extra: WeatherDetailArgs(title: title, data: weather, place: place),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WeatherCardData? weather = data?.isEmpty ?? true ? null : data;

    return SdCardV2(
      gradient: gradient(context),
      // **The tap and the chevron drop together where there is no reading.** A mark that promises a screen must never sit above a tap that opens an empty one.
      onTap: weather == null
          ? null
          : () => unawaited(_openDetail(context, weather)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdSpacingConstant.w16,
          vertical: SdSpacingConstant.h12,
        ),
        child: weather == null
            ? _Placeholder(
                label: emptyLabel,
                isLoading: isLoading,
                onRetry: onRetry,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // - the place arrives after the reading, so the card grows a line once rather than reserving one it may not fill.
                  if (place case final String name) ...<Widget>[
                    _PlaceLine(name: name),
                    SizedBox(height: SdSpacingConstant.h4),
                  ],
                  _Headline(
                    data: weather,
                    // Semantics carries what the glyph cannot say; the tap belongs to the card, so this is decoration.
                    trailing: Semantics(
                      label: l10n.weatherA11yDetail,
                      child: SdIconV2(
                        icon: AppIconConstant.disclosure,
                        size: AppIconSize.small,
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
class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.label,
    required this.isLoading,
    this.onRetry,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return SizedBox(
        height: SdSpacingConstant.h40,
        width: double.infinity,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(label, style: AppTextStyle.bodyMedium.secondary),
            ),
            // The auto-retry timer dies with the provider, so a miss that is not the network — a dead session, a backend with no credentials — waits forever without this.
            if (onRetry case final VoidCallback retry)
              SdButtonV2(
                variant: SdButtonVariantV2.text,
                size: SdButtonSizeV2.small,
                onPressed: retry,
                label: context.l10n.commonRetry,
              ),
          ],
        ),
      );
    }

    // Every measurement is read from the real thing rather than guessed, so the two cannot drift.
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
