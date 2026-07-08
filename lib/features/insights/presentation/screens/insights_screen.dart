import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.insightsTitle)),
      body: Center(child: Text(l10n.insightsPlaceholder)),
    );
  }
}
