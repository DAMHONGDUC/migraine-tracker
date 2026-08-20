part of 'attack_detail_screen.dart';

/// A "label … value" row with nothing to tap. Same shape and same reason as
/// [_EditableRow]: the value sits beside the label inside the title, and both
/// halves carry a flex so the row cannot overflow.
class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.bodyLarge,
            ),
          ),
          SizedBox(width: SdSpacingConstant.w8),
          Expanded(
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
    );
  }
}
