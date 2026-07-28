part of 'attack_detail_screen.dart';

class _IntensityDialog extends StatefulWidget {
  const _IntensityDialog({required this.initial});

  final int initial;

  @override
  State<_IntensityDialog> createState() => _IntensityDialogState();
}

class _IntensityDialogState extends State<_IntensityDialog> {
  late double _value = widget.initial.toDouble();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialog(
      title: l10n.logIntensityTitle,
      content: AppValueSlider(
        label: '${_value.round()}',
        value: _value,
        min: 1,
        max: 10,
        divisions: 9,
        accent: AppColors.intensity(_value.round()),
        onChanged: (v) => setState(() => _value = v),
      ),
      actions: [
        AppButton(
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
          label: l10n.commonCancel,
        ),
        AppButton(
          variant: AppButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(_value.round()),
          label: l10n.detailsSave,
        ),
      ],
    );
  }
}
