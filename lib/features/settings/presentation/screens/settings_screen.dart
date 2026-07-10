import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/enums/export_format.dart';
import '../controllers/settings_controller.dart';

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
    final selected = await showAppDialog<_LanguageChoice>(
      context,
      builder: (dialogContext) => AppDialog(
        title: l10n.settingsLanguage,
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
              AppDialogOption(
                label: label,
                selected:
                    choice.locale?.languageCode == current?.languageCode,
                onTap: () => Navigator.of(dialogContext).pop(choice),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await ref.read(localeControllerProvider.notifier).set(selected.locale);
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final format = await showAppDialog<ExportFormat>(
      context,
      builder: (dialogContext) => AppDialog(
        title: l10n.settingsExport,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDialogOption(
              icon: Icons.data_object,
              label: l10n.settingsExportJson,
              onTap: () => Navigator.of(dialogContext).pop(ExportFormat.json),
            ),
            AppDialogOption(
              icon: Icons.table_chart_outlined,
              label: l10n.settingsExportCsv,
              onTap: () => Navigator.of(dialogContext).pop(ExportFormat.csv),
            ),
          ],
        ),
      ),
    );
    if (format == null) return;
    await ref.read(settingsControllerProvider).export(format);
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showAppDialog<bool>(
      context,
      builder: (dialogContext) => AppDialog(
        title: l10n.settingsDeleteConfirmTitle,
        content: Text(
          l10n.settingsDeleteConfirmBody,
          style: context.textTheme.bodyMedium,
        ),
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

    await ref.read(settingsControllerProvider).deleteAll();
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

/// Wrapper so the dialog can distinguish "picked System (null)" from
/// "dismissed without picking".
class _LanguageChoice {
  const _LanguageChoice(this.locale);

  final Locale? locale;
}
