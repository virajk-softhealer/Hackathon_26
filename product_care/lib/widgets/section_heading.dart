import 'package:flutter/material.dart';

import '../app/app_localizations.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          tr(context, title),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      if (actionLabel != null)
        TextButton(onPressed: onAction, child: Text(tr(context, actionLabel!))),
    ],
  );
}
