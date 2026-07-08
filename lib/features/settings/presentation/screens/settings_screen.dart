import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../attacks/providers.dart';
import '../../../medications/providers.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _localeLabel(BuildContext context, Locale? locale) =>
      switch (locale?.languageCode) {
        'en' => context.l10n.settingsLanguageEnglish,
        'vi' => context.l10n.settingsLanguageVietnamese,
        _ => context.l10n.settingsLanguageSystem,
      };

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = ref.read(localeControllerProvider);
    final selected = await showDialog<_LanguageChoice>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.settingsLanguage),
        children: [
          for (final (choice, label) in [
            (const _LanguageChoice(null), l10n.settingsLanguageSystem),
            (
              const _LanguageChoice(Locale('en')),
              l10n.settingsLanguageEnglish,
            ),
            (
              const _LanguageChoice(Locale('vi')),
              l10n.settingsLanguageVietnamese,
            ),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(choice),
              child: Row(
                children: [
                  Icon(
                    choice.locale?.languageCode == current?.languageCode
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(label),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected != null) {
      await ref.read(localeControllerProvider.notifier).set(selected.locale);
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final format = await showDialog<_ExportFormat>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.settingsExport),
        children: [
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ExportFormat.json),
            child: Text(l10n.settingsExportJson),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(_ExportFormat.csv),
            child: Text(l10n.settingsExportCsv),
          ),
        ],
      ),
    );
    if (format == null) return;

    final attacks = await ref.read(attackRepositoryProvider).getAll();
    final medications = await ref.read(medicationRepositoryProvider).getAll();
    final service = ref.read(dataExportServiceProvider);
    final now = DateTime.now();
    final stamp = DateFormat('yyyy-MM-dd').format(now);

    final (content, filename, mime) = switch (format) {
      _ExportFormat.json => (
        service.toJson(attacks, medications, exportedAt: now),
        'baroease_export_$stamp.json',
        'application/json',
      ),
      _ExportFormat.csv => (
        service.toCsv(attacks),
        'baroease_export_$stamp.csv',
        'text/csv',
      ),
    };
    await ref
        .read(exportSinkProvider)
        .share(content: content, filename: filename, mimeType: mime);
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsDeleteConfirmTitle),
        content: Text(l10n.settingsDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsDeleteConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(dataWipeServiceProvider).wipeAll();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsDeleteDone)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(_localeLabel(context, locale)),
            onTap: () => _pickLanguage(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: Text(l10n.settingsExport),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: context.colorScheme.error,
            ),
            title: Text(
              l10n.settingsDelete,
              style: TextStyle(color: context.colorScheme.error),
            ),
            onTap: () => _deleteAll(context, ref),
          ),
        ],
      ),
    );
  }
}

enum _ExportFormat { json, csv }

/// Wrapper so the dialog can distinguish "picked System (null)" from
/// "dismissed without picking".
class _LanguageChoice {
  const _LanguageChoice(this.locale);

  final Locale? locale;
}
