import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/mapping_template.dart';
import '../models/mapping_template_json_mapper.dart';

/// HU-06: saved column-mapping templates ("Mi banco", "Wallet"...).
///
/// **Storage decision:** `shared_preferences`, not a Drift table.
/// `docs/requirements/fase-1/11-import-export.md` deliberately does not add one — a
/// template is a small, purely local UX convenience (it never needs to sync
/// across devices, never needs a foreign key from another table, and never
/// shows up in any query the rest of the app runs). One JSON-encoded list
/// under a single key is enough and avoids a schema bump for something this
/// disposable — same reasoning `ThemePreferenceDatasource` already
/// established for device-local, non-synced state in this project.
@lazySingleton
class MappingTemplatesLocalDatasource {
  const MappingTemplatesLocalDatasource(this._prefs);

  static const String _key = 'import_export_mapping_templates';

  final SharedPreferencesAsync _prefs;

  Future<List<MappingTemplate>> getTemplates() async {
    final raw = await _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return [
      for (final entry in decoded)
        MappingTemplateJsonMapper.fromJson(entry as Map<String, dynamic>),
    ];
  }

  Future<void> saveTemplate(MappingTemplate template) async {
    final templates = await getTemplates();
    final withoutSameName =
        templates.where((t) => t.name != template.name).toList();
    withoutSameName.add(template);
    await _write(withoutSameName);
  }

  Future<void> deleteTemplate(String name) async {
    final templates = await getTemplates();
    templates.removeWhere((t) => t.name == name);
    await _write(templates);
  }

  Future<void> _write(List<MappingTemplate> templates) => _prefs.setString(
        _key,
        jsonEncode([for (final t in templates) MappingTemplateJsonMapper.toJson(t)]),
      );
}
