part of 'attack_detail_screen.dart';

/// One "label … value ›" row of the detail screen.
class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.swatch,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  /// Optional colour dot shown *beside* the value — the value itself keeps the text token (colour never carries meaning through text).
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: _LabelledValue.tilePadding,
      title: _LabelledValue(
        label: label,
        // The dot travels WITH the value, so the cap covers both.
        value: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (swatch != null) ...<Widget>[
              SdColorDotV2(color: swatch!),
              SizedBox(width: SdSpacingConstant.w8),
            ],
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.bodyLarge,
              ),
            ),
          ],
        ),
      ),
      trailing: SdIconV2(
        icon: AppIconConstant.disclosure,
        size: AppIconSize.small,
        color: context.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
