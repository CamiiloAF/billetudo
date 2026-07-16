import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';

/// HU-07: creates a tag on the fly, from either the transaction form or the
/// tag filter. Purely a text prompt — the actual creation (and reuse of an
/// existing tag with the same name) lives in `CreateTag`.
class NewTagSheet extends StatefulWidget {
  const NewTagSheet({super.key});

  static Future<String?> show(BuildContext context) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (context) => const NewTagSheet(),
      );

  @override
  State<NewTagSheet> createState() => _NewTagSheetState();
}

class _NewTagSheetState extends State<NewTagSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          28 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.newTagSheetTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.newTagNameHint),
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_controller.text),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
