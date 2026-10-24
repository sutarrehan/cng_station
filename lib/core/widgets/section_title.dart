import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800))),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!))
      ]);
}
