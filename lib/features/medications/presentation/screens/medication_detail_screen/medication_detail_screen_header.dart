part of 'medication_detail_screen.dart';

/// The medication's name — shown and edited in the same field, so there is no "now you are reading, now you are editing" mode to enter.
class _Header extends ConsumerStatefulWidget {
  const _Header({required this.medication});

  final Medication medication;

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.medication.name,
  );
  final FocusNode _focus = FocusNode();

  /// Drives the suffix glyph: a pencil says the name can be changed, a tick says the change is saved by tapping it.
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(_Header oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow a rename from elsewhere (or our own echo), unless mid-edit.
    if (!_focus.hasFocus && widget.medication.name != _controller.text) {
      _controller.text = widget.medication.name;
    }
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Blur is still the one commit path — the tick just unfocuses, so tapping it and tapping away save through exactly the same line.
  void _onFocusChanged() {
    setState(() => _editing = _focus.hasFocus);
    if (!_focus.hasFocus) _commit();
  }

  Future<void> _commit() async {
    final String name = _controller.text.trim();

    // Emptied and left: revert rather than save a nameless medication.
    if (name.isEmpty) {
      _controller.text = widget.medication.name;
      return;
    }
    if (name == widget.medication.name) return;

    await ref
        .read(medicationsControllerProvider)
        .rename(widget.medication, name);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime? createdAt = widget.medication.createdAt;
    final String addedLabel = createdAt == null
        ? l10n.medicationsAddedUnknown
        : l10n.medicationsAddedOn(
            DateFormat.yMMMd(l10n.localeName).format(createdAt.toLocal()),
          );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV2.horizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SdTextFieldV2(
            controller: _controller,
            focusNode: _focus,
            label: l10n.medicationDetailName,
            hint: l10n.logMedicationNameHint,
            prefixIcon: AppIconConstant.medication,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _focus.unfocus(),
            suffix: SdIconButtonV2(
              icon: SdIconV2(
                icon: _editing ? AppIconConstant.confirm : AppIconConstant.edit,
                size: AppIconSize.row,
                color: _editing
                    ? context.colorScheme.secondary
                    : context.colorScheme.onSurfaceVariant,
              ),
              tooltip: _editing
                  ? l10n.medicationDetailSaveName
                  : l10n.medicationDetailEditName,
              onPressed: () =>
                  _editing ? _focus.unfocus() : _focus.requestFocus(),
            ),
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Text(addedLabel, style: AppTextStyle.bodySmall.secondary),
        ],
      ),
    );
  }
}
