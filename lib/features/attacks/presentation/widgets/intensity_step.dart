import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/context_extensions.dart';

/// First tap: pain intensity 1–10. Buttons are large enough to hit with a
/// shaking hand; selecting advances the flow immediately.
class IntensityStep extends StatelessWidget {
  const IntensityStep({required this.onSelected, super.key});

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Wrap(
          spacing: 16.w,
          runSpacing: 16.h,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 1; i <= 10; i++)
              SizedBox(
                width: 72.r,
                height: 72.r,
                child: FilledButton.tonal(
                  onPressed: () => onSelected(i),
                  child: FittedBox(
                    child: Text('$i', style: context.textTheme.headlineSmall),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
