import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.themeMode,
    required this.onThemeChanged,
    required this.onTestNotifications,
    required this.reminderDays,
    required this.onReminderDaysChanged,
    required this.onCreateBackup,
    required this.onRestoreBackup,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onTestNotifications;
  final Set<int> reminderDays;
  final ValueChanged<Set<int>> onReminderDaysChanged;
  final VoidCallback onCreateBackup;
  final VoidCallback onRestoreBackup;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    children: [
      Text(
        'Settings',
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      Text(
        'Make Product Care feel like yours',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      Card(
        child: Column(
          children: [
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE5F0E9),
                child: Icon(Icons.palette_outlined, color: Color(0xFF246B52)),
              ),
              title: Text(
                'Appearance',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('Choose light, dark, or system theme'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.settings_suggest_outlined),
                    label: Text('System'),
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
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFFFFEED8),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xFFB56818),
                ),
              ),
              title: Text(
                'Reminders',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('Shared reminder preferences'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              title: const Text('Remind me before'),
              subtitle: Text(_reminderSummary),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showReminderIntervals(context),
            ),
            ListTile(
              title: const Text('Test notifications'),
              subtitle: const Text('Preview an expiry reminder'),
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
                child: Icon(Icons.language_rounded, color: Color(0xFF5469AA)),
              ),
              title: const Text(
                'Language',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('English'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showMessage(
                context,
                'English is currently the available language.',
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Backup & restore'),
              subtitle: const Text('Save or restore a local copy'),
            ),
            ListTile(
              title: const Text('Create backup now'),
              subtitle: const Text('Products, loss history, and reminders'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onCreateBackup,
            ),
            ListTile(
              title: const Text('Restore a backup'),
              subtitle: const Text('Choose a backup saved on this device'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onRestoreBackup,
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Center(
        child: Text(
          'PRODUCT CARE  ·  YOUR HOME, WELL CARED FOR',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  String get _reminderSummary {
    final sortedDays = reminderDays.toList()..sort((a, b) => b.compareTo(a));
    if (sortedDays.isEmpty) return 'Off';
    return sortedDays
        .map((days) => '$days ${days == 1 ? 'day' : 'days'}')
        .join(' · ');
  }

  void _showReminderIntervals(BuildContext pageContext) {
    final selectedDays = Set<int>.from(reminderDays);
    showModalBottomSheet<void>(
      context: pageContext,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reminder intervals',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('Shared intervals for expiry and service reminders.'),
              const SizedBox(height: 12),
              for (final days in [1, 2, 3, 5, 7, 14, 30])
                CheckboxListTile(
                  value: selectedDays.contains(days),
                  onChanged: (selected) => setSheetState(() {
                    if (selected == true) {
                      selectedDays.add(days);
                    } else {
                      selectedDays.remove(days);
                    }
                  }),
                  title: Text('$days ${days == 1 ? 'day' : 'days'} before'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    onReminderDaysChanged(Set<int>.unmodifiable(selectedDays));
                    Navigator.pop(sheetContext);
                    _showMessage(
                      pageContext,
                      'Shared reminders updated for this session.',
                    );
                  },
                  child: const Text('Done'),
                ),
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
