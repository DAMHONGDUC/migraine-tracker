import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_style.dart';
import '../extensions/context_extensions.dart';

/// Opens the picker and returns the picked time, or null if dismissed — `AppTimePickerSheet(initialTime: ...).show(context)`.
class AppTimePickerSheet extends StatefulWidget {
  const AppTimePickerSheet({
    required this.initialTime,
    this.title,
    super.key,
    this.isEditMode = false,
  });

  final TimeOfDay initialTime;

  /// Sheet heading. Defaults to the generic "Reminder time" when null so the caller can name the action instead (e.g. "Add reminder" / "Edit reminder").
  final String? title;

  /// Row height shared by both wheels and the selection band behind them — must match for the band to sit exactly behind the centered row.
  static double get rowExtent => SdSpacingConstant.h44;

  /// Rows visible at once (odd, so one sits exactly centered).
  static const visibleRows = 5;

  final bool isEditMode;

  @override
  State<AppTimePickerSheet> createState() => _AppTimePickerSheetState();
}

/// Presents the picker as a scroll-controlled bottom sheet and returns the picked time, or null.
extension AppTimePickerSheetExt on AppTimePickerSheet {
  Future<TimeOfDay?> show(BuildContext context) =>
      showSdBottomSheetV2<TimeOfDay>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}

class _AppTimePickerSheetState extends State<AppTimePickerSheet> {
  late int _hour = widget.initialTime.hour;
  late int _minute = widget.initialTime.minute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // - Cancel/Done flank the title (iOS-style), not a row under the wheels — keeps the confirm action next to the title.
          SdSheetHeaderV2(
            title: widget.title ?? l10n.remindersPickTimeTitle,
            closeTooltip: l10n.commonClose,
            confirmTooltip: l10n.commonDone,
            action: widget.isEditMode
                ? SdSheetActionV2.edit
                : SdSheetActionV2.confirm,
            onConfirm: () => Navigator.of(
              context,
            ).pop(TimeOfDay(hour: _hour, minute: _minute)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              SdContentPaddingV2.horizontal,
              0,
              SdContentPaddingV2.horizontal,
              SdSpacingConstant.h16,
            ),
            child: SizedBox(
              height:
                  AppTimePickerSheet.rowExtent * AppTimePickerSheet.visibleRows,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const _SelectionBand(),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberWheel(
                          itemCount: 24,
                          initial: _hour,
                          semanticsLabel: l10n.remindersHourLabel,
                          onChanged: (value) => setState(() => _hour = value),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: SdSpacingConstant.w4,
                        ),
                        child: Text(':', style: AppTextStyle.headlineSmall),
                      ),
                      Expanded(
                        child: _NumberWheel(
                          itemCount: 60,
                          initial: _minute,
                          semanticsLabel: l10n.remindersMinuteLabel,
                          onChanged: (value) => setState(() => _minute = value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The rounded highlight band behind the centered row.
class _SelectionBand extends StatelessWidget {
  const _SelectionBand();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: AppTimePickerSheet.rowExtent,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
          border: Border.symmetric(
            horizontal: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

/// One scrollable, snapping column of zero-padded numbers (hours or minutes).
class _NumberWheel extends StatefulWidget {
  const _NumberWheel({
    required this.itemCount,
    required this.initial,
    required this.semanticsLabel,
    required this.onChanged,
  });

  final int itemCount;
  final int initial;
  final String semanticsLabel;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberWheel> createState() => _NumberWheelState();
}

class _NumberWheelState extends State<_NumberWheel> {
  late final _controller = FixedExtentScrollController(
    initialItem: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: AppTimePickerSheet.rowExtent,
      diameterRatio: 1.6,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: widget.onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.itemCount,
        builder: (context, index) => AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final centerItem = _controller.hasClients
                ? _controller.offset / AppTimePickerSheet.rowExtent
                : widget.initial.toDouble();
            final distance = (index - centerItem).abs();
            final emphasis = (1 - distance).clamp(0.0, 1.0);
            final label = index.toString().padLeft(2, '0');
            return Semantics(
              label: '${widget.semanticsLabel} $label',
              excludeSemantics: true,
              child: Center(
                child: Opacity(
                  opacity: 0.35 + 0.65 * emphasis,
                  child: Text(
                    label,
                    style: AppTextStyle.titleLarge
                        .copyWith(
                          color: Color.lerp(
                            AppColors.textPrimary,
                            AppColors.primary,
                            emphasis,
                          ),
                        )
                        .copyWith(
                          fontWeight: emphasis > 0.8
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
