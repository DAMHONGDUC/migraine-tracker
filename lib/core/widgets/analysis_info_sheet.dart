import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';

/// What one analysis card actually means, in the reader's own words.
///
/// **Every analysis card opens one** (owner's rule). A correlation states a
/// relationship in a sentence, and the sentence alone never says what was
/// compared against what, how the number was arrived at, or why the card is
/// still empty — so the card that cannot say it in place hands it to a sheet.
///
/// It carries no commit: there is nothing here to save, so the header's X is
/// the only way out and `SdSheetContentV2` draws no button.
class AnalysisInfoSheet extends StatelessWidget {
  const AnalysisInfoSheet({
    required this.title,
    required this.paragraphs,
    super.key,
  });

  /// Already localized: the card's own title, or the name of the analysis it
  /// explains where the card holds more than one — the pressure card's header
  /// says "Analysis" and its sheet says "Pressure correlation", because that
  /// is what the three paragraphs are about.
  final String title;

  /// Already localized, in reading order: what the card says, how it is worked
  /// out, and what it cannot claim.
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return SdSheetContentV2(
      title: title,
      closeTooltip: context.l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final String paragraph in paragraphs) ...<Widget>[
            Text(paragraph, style: AppTextStyle.bodyMedium),
            if (paragraph != paragraphs.last)
              SizedBox(height: SdSpacingConstant.h16),
          ],
        ],
      ),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension AnalysisInfoSheetExt on AnalysisInfoSheet {
  Future<void> show(BuildContext context) => showSdBottomSheetV2<void>(
    context,
    // Without it the route caps near half the screen and SdSheetContentV2's ceiling never applies.
    isScrollControlled: true,
    builder: (_) => this,
  );
}
