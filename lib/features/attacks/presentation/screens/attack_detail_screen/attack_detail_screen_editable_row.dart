part of 'attack_detail_screen.dart';

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

  /// Optional colour dot shown *beside* the value — the value itself keeps
  /// the text token (colour never carries meaning through text).
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: AppTextStyle.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (swatch != null) ...[
            SdColorDotV2(color: swatch!),
            SizedBox(width: SdSpacingConstant.w8),
          ],
          Text(value, style: AppTextStyle.bodyLarge),
          SizedBox(width: SdSpacingConstant.w4),
          SdIconV2(
            icon: Icons.chevron_right,
            size: SdSpacingConstant.r20,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
