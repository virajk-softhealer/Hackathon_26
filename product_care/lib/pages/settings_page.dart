import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../widgets/reminder_interval_sheet.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.themeMode,
    required this.onThemeChanged,
    required this.onTestNotifications,
    required this.reminderDays,
    required this.onReminderDaysChanged,
    required this.languageCode,
    required this.onLanguageChanged,
    required this.onCreateBackup,
    required this.onRestoreBackup,
    required this.onExportExcel,
    this.onExportCsv,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onTestNotifications;
  final Set<int> reminderDays;
  final ValueChanged<Set<int>> onReminderDaysChanged;
  final String languageCode;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onCreateBackup;
  final VoidCallback onRestoreBackup;
  final VoidCallback onExportExcel;
  final VoidCallback? onExportCsv;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    children: [
      Text(
        tr(context, 'Settings'),
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      Text(
        tr(context, 'Make Product Care feel like yours'),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE5F0E9),
                child: Icon(Icons.palette_rounded, color: Color(0xFF246B52)),
              ),
              title: Text(
                tr(context, 'Appearance'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                tr(context, 'Choose light, dark, or system theme'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(
                      Icons.light_mode_rounded,
                      color: Color(0xFFE5A62D),
                    ),
                    label: Text(tr(context, 'Light')),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(
                      Icons.dark_mode_rounded,
                      color: Color(0xFF6979D2),
                    ),
                    label: Text(tr(context, 'Dark')),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(
                      Icons.settings_suggest_rounded,
                      color: Color(0xFF3B9B86),
                    ),
                    label: Text(tr(context, 'System')),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (values) => onThemeChanged(values.first),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFEED8),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFE28A37),
                ),
              ),
              title: Text(
                tr(context, 'Reminders'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(tr(context, 'Shared reminder preferences')),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(
                Icons.schedule_rounded,
                color: Color(0xFF8B61CC),
              ),
              title: Text(tr(context, 'Remind me before')),
              subtitle: Text(_reminderSummary(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showReminderInterval(context),
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFFE28A37),
              ),
              title: Text(tr(context, 'Test notifications')),
              subtitle: Text(tr(context, 'Preview an expiry reminder')),
              trailing: const Icon(Icons.chevron_right),
              onTap: onTestNotifications,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE7ECFA),
                child: Icon(Icons.translate_rounded, color: Color(0xFF3E7BDB)),
              ),
              title: Text(
                tr(context, 'Language'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(_languageName(context, languageCode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguagePicker(context),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE4F2E9),
                child: Icon(Icons.backup_rounded, color: Color(0xFF278765)),
              ),
              title: Text(
                tr(context, 'Backup & restore'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(tr(context, 'Back up or restore your local data')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDataMenu(context),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Center(
        child: Text(
          tr(context, 'PRODUCT CARE  ·  YOUR HOME, WELL CARED FOR'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  String _reminderSummary(BuildContext context) {
    if (reminderDays.isEmpty) return tr(context, 'Off');
    final days = reminderDays.first;
    return tr(context, days == 1 ? '{days} day before' : '{days} days before', {
      'days': days,
    });
  }

  String _languageName(BuildContext context, String code) => switch (code) {
    'hi' => tr(context, 'Hindi'),
    'gu' => tr(context, 'Gujarati'),
    _ => tr(context, 'English'),
  };

  void _showReminderInterval(BuildContext pageContext) {
    showModalBottomSheet<void>(
      context: pageContext,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => ReminderIntervalSheet(
        reminderDays: reminderDays,
        onSave: (days) {
          onReminderDaysChanged({days});
          _showMessage(
            pageContext,
            tr(pageContext, 'Reminder preference saved.'),
          );
        },
      ),
    );
  }

  void _showLanguagePicker(BuildContext pageContext) {
    var selected = languageCode;
    showDialog<void>(
      context: pageContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(tr(dialogContext, 'Choose language')),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: RadioGroup<String>(
            groupValue: selected,
            onChanged: (value) {
              if (value != null) setDialogState(() => selected = value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in const [
                  ('gu', 'Gujarati', 'ગુજરાતી'),
                  ('en', 'English', 'English'),
                  ('hi', 'Hindi', 'हिन्दी'),
                ])
                  RadioListTile<String>(
                    value: option.$1,
                    title: Text(option.$3),
                    subtitle: Text(tr(dialogContext, option.$2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr(dialogContext, 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onLanguageChanged(selected);
              },
              child: Text(tr(dialogContext, 'Done')),
            ),
          ],
        ),
      ),
    );
  }

  void _showDataMenu(BuildContext pageContext) {
    showModalBottomSheet<void>(
      context: pageContext,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE4F2E9),
                  child: Icon(Icons.backup_rounded, color: Color(0xFF278765)),
                ),
                title: Text(tr(sheetContext, 'Create backup now')),
                subtitle: Text(
                  tr(sheetContext, 'Products, loss history, and reminder days'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onCreateBackup();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE7ECFA),
                  child: Icon(Icons.restore_rounded, color: Color(0xFF3E7BDB)),
                ),
                title: Text(tr(sheetContext, 'Restore a backup')),
                subtitle: Text(
                  tr(sheetContext, 'Choose a backup saved on this device'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onRestoreBackup();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F4E8),
                  child: Icon(
                    Icons.table_view_rounded,
                    color: Color(0xFF16834A),
                  ),
                ),
                title: Text(tr(sheetContext, 'Export and share Excel (.xlsx)')),
                subtitle: Text(
                  tr(sheetContext, 'Share products and stock-loss data'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onExportExcel();
                },
              ),
              if (onExportCsv != null)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFDEEE9),
                    child: Icon(
                      Icons.description_outlined,
                      color: Color(0xFFD35400),
                    ),
                  ),
                  title: Text(tr(sheetContext, 'Export and share CSV (.csv)')),
                  subtitle: Text(
                    tr(
                      sheetContext,
                      'Universal comma-separated file with clean dates',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onExportCsv?.call();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
