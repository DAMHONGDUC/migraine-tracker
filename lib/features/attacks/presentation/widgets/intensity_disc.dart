import 'package:flutter/material.dart';

import '../../../../core/constants/log_flow_constant.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';

/// The severity number in its coloured disc — the log flow's tappable
/// intensity choice and the detail screen's header badge are the same mark at
/// two sizes.
///
/// Severity lives in the fill and border; the number wears the text token so
/// it stays readable at every step of the ramp.
class IntensityDisc extends StatelessWidget {
  const IntensityDisc({required this.value, required this.size, super.key});


  final int value;

  /// Diameter — an `SdSpacingConstant.r*`, never a raw number.
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.intensity(value);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: LogFlowConstant.intensityDiscFillAlpha),
        border: Border.all(color: color, width: LogFlowConstant.intensityDiscBorderWidth),
      ),
      child: FittedBox(
        child: Text(
          '$value',
          style: AppTextStyle.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
