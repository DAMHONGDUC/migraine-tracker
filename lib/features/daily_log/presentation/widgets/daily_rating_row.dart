import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';

/// One 1–5 question: the five targets, and the word for whichever is picked.
///
/// Five labelled tiles do not fit a 393pt row, and five bare numbers say
/// nothing, so the number is the target and the word sits under the row for the
/// one that is chosen.
class DailyRatingRow extends StatelessWidget {
  const DailyRatingRow({
    required this.question,
    required this.labels,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String question;

  /// The five words, worst first — index 0 is rating 1.
  final List<String> labels;

  /// 1–5, or null while the question is unanswered.
  final int? selected;

  final ValueChanged<int> onSelected;

  /// The row's own height: a number in a circle, not a measure of the screen.
  static const double tileHeight = 56;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(question, style: AppTextStyle.titleSmall),
        SizedBox(height: SdSpacingConstant.h12),
        Row(
          children: <Widget>[
            for (int rating = 1; rating <= labels.length; rating++) ...<Widget>[
              if (rating > 1) SizedBox(width: SdSpacingConstant.w8),
              Expanded(
                child: _RatingTile(
                  rating: rating,
                  label: labels[rating - 1],
                  selected: selected == rating,
                  onTap: () => onSelected(rating),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: SdSpacingConstant.h8),
        // Always drawn, so picking an answer never moves the question below it.
        Text(
          selected == null ? '' : labels[selected! - 1],
          style: AppTextStyle.bodySmall.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({
    required this.rating,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int rating;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      // The word, not the number: "3" tells a screen reader nothing about what was picked.
      label: label,
      excludeSemantics: true,
      child: SdPressableScaleV2(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: DailyRatingRow.tileHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(SdSpacingConstant.r16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            '$rating',
            style: AppTextStyle.titleMedium.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
