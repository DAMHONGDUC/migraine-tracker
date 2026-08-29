import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/log_flow_constant.dart';
import '../../../../core/extensions/aura_label.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/enums/aura_type.dart';

/// Records which auras an attack came with.
class AuraPickerSheet extends StatefulWidget {
  const AuraPickerSheet({required this.selected, super.key});

  final List<AuraType>? selected;

  Future<({List<AuraType>? aura})?> show(BuildContext context) =>
      showSdBottomSheetV2<({List<AuraType>? aura})>(
        context,
        builder: (_) => this,
      );

  @override
  State<AuraPickerSheet> createState() => _AuraPickerSheetState();
}

class _AuraPickerSheetState extends State<AuraPickerSheet> {
  late final Set<AuraType> _picked = <AuraType>{...?widget.selected};

  void _toggle(AuraType type) => setState(() {
    if (!_picked.remove(type)) _picked.add(type);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SdSheetContentV2(
      title: l10n.auraSheetTitle,
      closeTooltip: l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The word means nothing to a good half of the people who get one.
          Text(l10n.auraSheetHint, style: AppTextStyle.bodySmall.secondary),
          SizedBox(height: SdSpacingConstant.h12),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            // The sheet owns the scrolling.
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: LogFlowConstant.optionsPerRow,
              mainAxisSpacing: SdSpacingConstant.h8,
              crossAxisSpacing: SdSpacingConstant.w8,
              mainAxisExtent: SdSpacingConstant.h64,
            ),
            itemCount: AuraType.values.length,
            itemBuilder: (BuildContext context, int index) {
              final AuraType type = AuraType.values[index];

              return _AuraTile(
                type: type,
                selected: _picked.contains(type),
                onTap: () => _toggle(type),
              );
            },
          ),
          SizedBox(height: SdSpacingConstant.h16),
          // Saving with nothing picked IS the "no aura" answer, so the button says so.
          SdButtonV2(
            variant: SdButtonVariantV2.primary,
            label: _picked.isEmpty ? l10n.auraNone : l10n.commonDone,
            onPressed: () => Navigator.of(
              context,
            ).pop((aura: <AuraType>[..._picked])),
          ),
          // Only once there is something to take back — a "clear" on a field that was never set says nothing.
          if (widget.selected != null)
            SdButtonV2(
              variant: SdButtonVariantV2.text,
              label: l10n.auraNotRecorded,
              onPressed: () => Navigator.of(context).pop((aura: null)),
            ),
        ],
      ),
    );
  }
}

class _AuraTile extends StatelessWidget {
  const _AuraTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final AuraType type;
  final bool selected;
  final VoidCallback onTap;

  /// A glyph per kind, because colour is never the only signal and because "sensory" is a word people recognise faster as a picture.
  static const Map<AuraType, IconData> _icons = <AuraType, IconData>{
    AuraType.visual: AppIconConstant.auraVisual,
    AuraType.sensory: AppIconConstant.auraSensory,
    AuraType.speech: AppIconConstant.auraSpeech,
    AuraType.motor: AppIconConstant.auraMotor,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Color color = selected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: type.label(l10n),
      excludeSemantics: true,
      child: SdPressableScaleV2(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: SdSpacingConstant.w12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              SdIconV2(
                icon: _icons[type]!,
                size: AppIconSize.medium,
                color: color,
              ),
              SizedBox(width: SdSpacingConstant.w8),
              Expanded(
                child: Text(
                  type.label(l10n),
                  style: AppTextStyle.bodySmall.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
