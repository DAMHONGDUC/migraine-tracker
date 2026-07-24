import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_text_style.dart';
import 'app_bottom_sheet.dart';

/// Opens a single-choice filter sheet: a plain radio list of [options],
/// [selected] pre-checked. Returns the picked value, or null if dismissed
/// without a pick. Generic over the filtered dimension — [labelBuilder]
/// supplies the localized label per value, so this has no opinion about
/// what's being filtered.
///
/// Shared by every screen that filters a list along one enum-like axis:
/// History's period filter, and the medications tab's three independent
/// filters (date added, reminder, usage) — each opens its own instance of
/// this sheet rather than one combined multi-axis picker, so every filter
/// stays a simple, single-tap choice.
Future<T?> showAppFilterSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T value) labelBuilder,
}) {
  return showAppBottomSheet<T>(
    context,
    builder: (_) => _FilterSheet<T>(
      title: title,
      options: options,
      selected: selected,
      labelBuilder: labelBuilder,
    ),
  );
}

/// The filter pill (icon + current value + expand chevron); tapping opens
/// [showAppFilterSheet]. Meant to sit at the top of the filtered content,
/// below the app bar — same slot History used before this was generalized.
class AppFilterChip<T> extends StatelessWidget {
  const AppFilterChip({
    required this.label,
    required this.selected,
    required this.options,
    required this.optionLabelBuilder,
    required this.onSelected,
    required this.sheetTitle,
    this.count,
    this.countLabelBuilder,
    super.key,
  }) : assert(
         count == null || countLabelBuilder != null,
         'countLabelBuilder is required whenever count is passed',
       );

  /// Text shown on the closed chip. Kept separate from [optionLabelBuilder]
  /// because a screen with one filter (History) can just show the picked
  /// value, but a screen with several filters side by side (the medications
  /// tab) needs each chip to also carry its own axis name — otherwise
  /// several chips all resting on their default value would all read "All"
  /// with nothing to tell them apart. The caller decides; this widget has
  /// no way to know which value in [options] means "no filter".
  final String label;

  final T selected;
  final List<T> options;

  /// Labels one option inside the open sheet's radio list. Deliberately
  /// separate from [label] — the sheet lists every option by its own value,
  /// never by axis name (that would repeat the sheet's [sheetTitle] on
  /// every row).
  final String Function(T value) optionLabelBuilder;
  final ValueChanged<T> onSelected;

  /// Title shown above the option list in the sheet, and reused as the
  /// chip's own accessibility label context.
  final String sheetTitle;

  /// How many items the current selection matches — appended to the label
  /// via [countLabelBuilder] when non-null (e.g. "All (10)").
  final int? count;

  /// Combines the selected option's label with [count] into display text.
  /// Callers that pass [count] must supply this through their own ARB
  /// entry — word order around a count varies by locale, so this widget
  /// never hardcodes the composed string itself (hard rule: every
  /// user-facing string goes through intl). Ignored when [count] is null.
  final String Function(String label, int count)? countLabelBuilder;

  Future<void> _open(BuildContext context) async {
    final picked = await showAppFilterSheet<T>(
      context,
      title: sheetTitle,
      options: options,
      selected: selected,
      labelBuilder: optionLabelBuilder,
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppSpacingConstant.r20),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacingConstant.r20),
        onTap: () => _open(context),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacingConstant.w14,
            vertical: AppSpacingConstant.h8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list,
                size: AppSpacingConstant.r16,
                color: scheme.primary,
              ),
              SizedBox(width: AppSpacingConstant.w6),
              Text(
                count == null ? label : countLabelBuilder!(label, count!),
                style: AppTextStyle.labelLarge,
              ),
              SizedBox(width: AppSpacingConstant.w2),
              Icon(
                Icons.expand_more,
                size: AppSpacingConstant.r18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet<T> extends StatelessWidget {
  const _FilterSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.labelBuilder,
  });

  final String title;
  final List<T> options;
  final T selected;
  final String Function(T value) labelBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacingConstant.w24,
              AppSpacingConstant.h4,
              AppSpacingConstant.w24,
              AppSpacingConstant.h12,
            ),
            child: Text(title, style: AppTextStyle.titleMedium),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    leading: Icon(
                      option == selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: option == selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      size: AppSpacingConstant.r22,
                    ),
                    title: Text(labelBuilder(option)),
                    onTap: () => Navigator.of(context).pop(option),
                  ),
              ],
            ),
          ),
          SizedBox(height: AppSpacingConstant.h8),
        ],
      ),
    );
  }
}
