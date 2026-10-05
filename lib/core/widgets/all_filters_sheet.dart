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
  /// draft already is, which disables the button rather than hiding it.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final double gap = SdSpacingConstant.h16;

    return SdSheetContentV2(
      title: context.l10n.filtersSheetTitle,
      closeTooltip: context.l10n.commonClose,
      confirmLabel: context.l10n.filtersApply,
      onConfirm: onApply,
      footer: SdButtonV2(
        variant: SdButtonVariantV2.text,
        label: context.l10n.filtersClearAll,
        onPressed: onClear,
      ),
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
