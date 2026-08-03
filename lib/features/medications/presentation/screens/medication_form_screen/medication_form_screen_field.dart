part of 'medication_form_screen.dart';

/// One labelled field of the form, with the gap that separates it from the
/// next one — so the screen lists fields and never spacing.
class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: SdSpacingConstant.h16),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}
