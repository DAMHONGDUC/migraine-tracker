import 'package:flutter/material.dart';

/// First tap: pain intensity 1–10. Buttons are large enough to hit with a
/// shaking hand; selecting advances the flow immediately.
class IntensityStep extends StatelessWidget {
  const IntensityStep({required this.onSelected, super.key});

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 1; i <= 10; i++)
              SizedBox(
                width: 72,
                height: 72,
                child: FilledButton.tonal(
                  onPressed: () => onSelected(i),
                  child: Text(
                    '$i',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
