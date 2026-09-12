import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// One heading + body block of a rendered legal document. [heading] is
/// `null` for the intro paragraph that precedes the document's first `## `
/// heading.
class LegalSection {
  const LegalSection({required this.heading, required this.body});

  final String? heading;
  final String body;
}

/// Splits a legal document's raw markdown (`lib/core/legal/assets/*.md`)
/// into the [LegalSection]s the viewer renders (Pencil `Legal Section`,
/// `i5tj1`: a bold heading + a body paragraph, repeated).
///
/// Deliberately not a full markdown renderer — the documents are plain,
/// heading-delimited prose. This: drops the `# ` document title (the page
/// header already shows it), drops the `## Índice` section (a list of
/// in-document anchor links with no destination inside the app), drops `---`
/// dividers, and strips `**bold**`/`[text](url)` markup down to plain text.
List<LegalSection> parseLegalSections(String markdown) {
  final sections = <LegalSection>[];
  String? currentHeading;
  final buffer = StringBuffer();

  void flush() {
    final body = _stripInlineMarkdown(buffer.toString().trim());
    if (body.isNotEmpty) {
      sections.add(LegalSection(heading: currentHeading, body: body));
    }
    buffer.clear();
  }

  for (final rawLine in markdown.split('\n')) {
    final line = rawLine.trimRight();
    if (line.startsWith('# ')) {
      continue;
    }
    if (line.startsWith('## ')) {
      flush();
      currentHeading = line.substring(3).trim();
      continue;
    }
    if (line.trim() == '---') {
      continue;
    }
    buffer.writeln(line);
  }
  flush();

  return sections.where((section) => section.heading != 'Índice').toList();
}

String _stripInlineMarkdown(String text) => text
    .replaceAll('**', '')
    .replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (match) => match.group(1) ?? '',
    )
    .trim();

/// Renders one [LegalSection] (Pencil `Legal Section`, `i5tj1`): a 16/700
/// heading (omitted when [LegalSection.heading] is `null`) plus a 15/500
/// body at `lineHeight: 1.6` — both in `$text-primary`, since a long
/// document's hierarchy comes from size/weight, not from a dimmer body
/// color (`design-system/billetudo/MASTER.md`).
class LegalSectionView extends StatelessWidget {
  const LegalSectionView({required this.section, super.key});

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.heading case final heading?) ...[
          Text(
            heading,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          section.body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
        ),
      ],
    );
  }
}
