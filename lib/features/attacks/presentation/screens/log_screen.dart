import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.logTitle)),
      body: Center(child: Text(l10n.logPlaceholder)),
    );
  }
}
