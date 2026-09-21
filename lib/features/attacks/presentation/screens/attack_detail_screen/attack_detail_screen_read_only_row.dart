part of 'attack_detail_screen.dart';

/// A "label … value" row with nothing to tap.
///
/// The same [_LabelledValue] the editable row uses: the two differ by a
/// chevron and a tap, never by how the line divides.
class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: _LabelledValue(
        label: label,
        value: Text(
          value,
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.bodyLarge,
        ),
      ),
    );
  }
}
