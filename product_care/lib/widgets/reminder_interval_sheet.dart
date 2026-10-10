import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_localizations.dart';

class ReminderIntervalSheet extends StatefulWidget {
  const ReminderIntervalSheet({
    required this.reminderDays,
    required this.onSave,
    super.key,
  });

  final Set<int> reminderDays;
  final ValueChanged<int> onSave;

  @override
  State<ReminderIntervalSheet> createState() => _ReminderIntervalSheetState();
}

class _ReminderIntervalSheetState extends State<ReminderIntervalSheet> {
  late final TextEditingController _customDays;
  late int _selected;

  @override
  void initState() {
    super.initState();
    final sorted = widget.reminderDays.toList()..sort();
    final existing = widget.reminderDays.length == 1
        ? widget.reminderDays.first
        : widget.reminderDays.contains(3)
        ? 3
        : sorted.isEmpty
        ? 3
        : sorted.last;
    _selected = existing >= 1 && existing <= 5 ? existing : 0;
    _customDays = TextEditingController(
      text: _selected == 0 ? '$existing' : '',
    );
  }

  @override
  void dispose() {
    _customDays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'Reminder interval'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr(context, 'Shared for expiry and service reminders.'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              RadioGroup<int>(
                groupValue: _selected,
                onChanged: (value) {
                  if (value != null) setState(() => _selected = value);
                },
                child: Column(
                  children: [
                    for (final days in [1, 2, 3, 4, 5])
                      RadioListTile<int>(
                        value: days,
                        title: Text(
                          tr(
                            context,
                            days == 1
                                ? '{days} day before'
                                : '{days} days before',
                            {'days': days},
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    RadioListTile<int>(
                      value: 0,
                      title: Text(tr(context, 'Custom days')),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ],
                ),
              ),
              if (_selected == 0)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 54,
                    right: 8,
                    bottom: 10,
                  ),
                  child: TextField(
                    controller: _customDays,
                    autofocus: false,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: tr(context, 'Enter days (1–365)'),
                      prefixIcon: const Icon(Icons.edit_calendar_outlined),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(tr(context, 'Save reminder')),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _save() {
    final days = _selected == 0 ? int.tryParse(_customDays.text) : _selected;
    if (days == null || days < 1 || days > 365) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'Enter a valid number of days.'))),
      );
      return;
    }
    widget.onSave(days);
    Navigator.pop(context);
  }
}
