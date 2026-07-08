import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.insightsTitle)),
      body: Center(child: Text(l10n.insightsPlaceholder)),
    );
  }
}
