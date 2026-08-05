import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/sections/alerts_section.dart';

/// Pressure-drop alerts: the enable switch and the threshold, together.
/// Pushed from the Settings row, which shows only whether it is On/Off.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SdScaffoldV2(
      title: Text(context.l10n.alertsScreenTitle, style: AppTextStyle.titleLarge),
      body: ListView(
        // Full-bleed: both rows are ListTiles, which inset themselves.
        padding: SdContentPaddingV2.fullBleed(context),
        children: const [AlertsSection()],
      ),
    );
  }
}
