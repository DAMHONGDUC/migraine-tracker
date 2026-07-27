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
    final color = AppColors.intensity(_value.round());
    return AppDialog(
      title: l10n.logIntensityTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_value.round()}', style: AppTextStyle.displaySmall.w600),
          Slider(
            value: _value,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: color,
            onChanged: (v) => setState(() => _value = v),
          ),
        ],
      ),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.of(context).pop(),
          label: l10n.commonCancel,
        ),
        AppButton.primary(
          onPressed: () => Navigator.of(context).pop(_value.round()),
          label: l10n.detailsSave,
        ),
      ],
    );
  }
}
