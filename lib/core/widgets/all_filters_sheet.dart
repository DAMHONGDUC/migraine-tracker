import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';

/// Every filter axis of a list in one sheet, one `SdFilterSectionV2` each,
/// separated by a divider.
///
/// Look only: the caller holds the draft, rebuilds [sections] as it moves, and
/// commits it from [onApply] — a highlight moved here narrows nothing until
/// then (`SdSheetContentV2`'s commit rule). Shared by History and the
/// medications tab so the two sheets cannot drift apart.
class AllFiltersSheet extends StatelessWidget {
  const AllFiltersSheet({
    required this.sections,
    required this.onApply,
    required this.onClear,
    super.key,
  });

  final List<Widget> sections;

  final VoidCallback onApply;

  /// Puts every axis of the draft back to "all", in the sheet. Null while the
  /// draft already is, which disables Reset rather than hiding it.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final double gap = SdSpacingConstant.h16;

    return SdSheetContentV2(
      title: context.l10n.filtersSheetTitle,
      closeTooltip: context.l10n.commonClose,
      // No confirmLabel: Apply shares the pinned footer with Reset, halves of one row — outlined resets, primary commits (owner's rule).
      footer: Row(
        children: <Widget>[
          Expanded(
            child: SdButtonV2(
              variant: SdButtonVariantV2.outlined,
              label: context.l10n.filtersReset,
              onPressed: onClear,
            ),
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: SdButtonV2(
              variant: SdButtonVariantV2.primary,
              label: context.l10n.filtersApply,
              onPressed: onApply,
            ),
          ),
        ],
      ),
      footerTopPadding: SdSpacingConstant.sp16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < sections.length; i++) ...<Widget>[
            if (i > 0) ...<Widget>[
              SizedBox(height: gap),
              const SdDividerV2(),
              SizedBox(height: gap),
            ],
            sections[i],
          ],
        ],
      ),
    );
  }
}
