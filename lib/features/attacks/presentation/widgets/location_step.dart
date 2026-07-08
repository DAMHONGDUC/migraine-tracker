import 'package:flutter/material.dart';

import '../../../../core/extensions/head_location_label.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/enums/head_location.dart';

/// Second tap: where the pain is. Selecting advances immediately.
class LocationStep extends StatelessWidget {
  const LocationStep({required this.onSelected, super.key});

  final ValueChanged<HeadLocation> onSelected;

  static const _icons = {
    HeadLocation.left: Icons.arrow_back,
    HeadLocation.right: Icons.arrow_forward,
    HeadLocation.front: Icons.north,
    HeadLocation.back: Icons.south,
    HeadLocation.whole: Icons.circle_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (final location in HeadLocation.values) ...[
          SizedBox(
            height: 64,
            child: FilledButton.tonalIcon(
              onPressed: () => onSelected(location),
              icon: Icon(_icons[location]),
              label: Text(
                location.label(l10n),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
