import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_location_label.dart';
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
    return ListView(
      padding: EdgeInsets.all(AppSpacingConstant.w24),
      children: [
        for (final location in HeadLocation.values) ...[
          SizedBox(
            height: AppSpacingConstant.h64,
            child: FilledButton.tonalIcon(
              onPressed: () => onSelected(location),
              icon: Icon(_icons[location]),
              label: Text(
                location.label(context.l10n),
                style: context.textTheme.titleMedium,
              ),
            ),
          ),
          SizedBox(height: AppSpacingConstant.h12),
        ],
      ],
    );
  }
}
