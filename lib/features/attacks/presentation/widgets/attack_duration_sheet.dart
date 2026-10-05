import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/attack_duration_constant.dart';
import '../../../../core/constants/log_flow_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/date_time_utils.dart';
import 'attack_option_tile.dart';

/// Records how long an attack lasted, after the fact: a preset tap answers at once, or hours and minutes typed in commit from the pinned button.
class AttackDurationSheet extends StatefulWidget {
  const AttackDurationSheet({
    required this.startedAt,
    required this.endedAt,
    super.key,
  });

  final DateTime startedAt;
  final DateTime? endedAt;

  @override
  State<AttackDurationSheet> createState() => _AttackDurationSheetState();
}

class _AttackDurationSheetState extends State<AttackDurationSheet> {
  /// Digits a box takes — 999h is past any attack, and a minute is two digits.
  static const int _hoursDigits = 3;
  static const int _minutesDigits = 2;

  late final Duration? _recorded = widget.endedAt?.difference(
    widget.startedAt,
  );
  late final TextEditingController _hours = TextEditingController(
    text: _recorded == null ? '' : '${DateTimeUtils.splitHm(_recorded).$1}',
  );
  late final TextEditingController _minutes = TextEditingController(
    text: _recorded == null ? '' : '${DateTimeUtils.splitHm(_recorded).$2}',
  );

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _pick(Duration duration) =>
      Navigator.of(context).pop((endedAt: widget.startedAt.add(duration)));

  /// Minutes past the hour can only be 0–59; more is refused, not carried into hours.
  bool get _minutesInvalid => (int.tryParse(_minutes.text) ?? 0) > 59;

  /// What the boxes add up to, or null while that is nothing or refused — which is what disables the button.
  Duration? get _typed {
    final Duration typed = Duration(
      hours: int.tryParse(_hours.text) ?? 0,
      minutes: int.tryParse(_minutes.text) ?? 0,
    );

    if (_minutesInvalid || typed == Duration.zero) return null;
    return typed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Duration sinceStart = DateTime.now().toUtc().difference(
      widget.startedAt,
    );
    final Duration? typed = _typed;

    return SdSheetContentV2(
      title: l10n.attackDurationSheetTitle,
      closeTooltip: l10n.commonClose,
      // Save for a first answer, Update over a recorded one; only the typed boxes commit here — a preset tap already has.
      confirmLabel: _recorded == null ? l10n.commonSave : l10n.commonUpdate,
      onConfirm: typed == null ? null : () => _pick(typed),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The common case for an attack still running: the user is looking at the app because it has just stopped.
          if (!sinceStart.isNegative)
            SizedBox(
              // The same box the grid gives every other option: left to size itself it shrank to its line of text, a thin pill above ten chunky tiles.
              height: AttackOptionTile.height,
              child: AttackOptionTile(
                label: l10n.attackDurationEndedNow,
                detail: sinceStart.label(l10n),
                selected: false,
                onTap: () => _pick(sinceStart),
              ),
            ),
          SizedBox(height: SdSpacingConstant.h8),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            // The sheet owns the scrolling.
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: LogFlowConstant.optionsPerRow,
              mainAxisSpacing: SdSpacingConstant.h8,
              crossAxisSpacing: SdSpacingConstant.w8,
              mainAxisExtent: AttackOptionTile.height,
            ),
            itemCount: AttackDurationConstant.options.length,
            itemBuilder: (BuildContext context, int index) {
              final Duration option = AttackDurationConstant.options[index];

              return AttackOptionTile(
                label: option.label(l10n),
                selected: _recorded == option,
                onTap: () => _pick(option),
              );
            },
          ),
          SizedBox(height: SdSpacingConstant.h16),
          Text(l10n.attackDurationCustomTitle, style: AppTextStyle.titleSmall),
          SizedBox(height: SdSpacingConstant.h8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _DurationField(
                  controller: _hours,
                  label: l10n.attackDurationHoursLabel,
                  digits: _hoursDigits,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(width: SdSpacingConstant.w8),
              Expanded(
                child: _DurationField(
                  controller: _minutes,
                  label: l10n.attackDurationMinutesLabel,
                  digits: _minutesDigits,
                  errorText: _minutesInvalid
                      ? l10n.attackDurationMinutesInvalid
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h8),
          // Only offered once there is something to take back — a "clear" on a field that was never set says nothing.
          if (widget.endedAt != null)
            SdButtonV2(
              variant: SdButtonVariantV2.text,
              onPressed: () => Navigator.of(context).pop((endedAt: null)),
              label: l10n.attackDurationNotRecorded,
            ),
        ],
      ),
    );
  }
}

/// One whole-number box — digits only, so neither a decimal hour nor a sign can be typed.
class _DurationField extends StatelessWidget {
  const _DurationField({
    required this.controller,
    required this.label,
    required this.digits,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;

  /// Longest number the box takes.
  final int digits;

  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return SdTextFieldV2(
      controller: controller,
      label: label,
      errorText: errorText,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(digits),
      ],
      onChanged: onChanged,
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension AttackDurationSheetExt on AttackDurationSheet {
  Future<({DateTime? endedAt})?> show(BuildContext context) =>
      showSdBottomSheetV2<({DateTime? endedAt})>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
