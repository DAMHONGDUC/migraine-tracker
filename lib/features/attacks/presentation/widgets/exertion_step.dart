import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/enums/exertion_level.dart';
import 'exertion_level_picker.dart';

/// Fourth step: how hard the user was moving around the attack.
///
/// Arrives on [ExertionLevel.none] — the common answer — so Next works
/// immediately and this step can never stand between the user and a saved
/// attack (hard rule 5).
class ExertionStep extends StatelessWidget {
  const ExertionStep({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ExertionLevel? selected;
  final ValueChanged<ExertionLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV2.horizontal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ExertionLevelPicker(selected: selected, onSelected: onSelected),
          SizedBox(height: SdSpacingConstant.h16),
          Text(
            context.l10n.logExertionOptional,
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySmall.secondary,
          ),
        ],
      ),
    );
  }
}
