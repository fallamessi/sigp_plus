import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app.dart';

class RelationConfig {
  const RelationConfig({
    required this.table,
    this.labelFields = const ['nom', 'libelle', 'code'],
  });

  final String table;
  final List<String> labelFields;
}

class CrudPage extends ConsumerStatefulWidget {
  const CrudPage({
    super.key,
    required this.title,
    required this.entity,
    required this.fields,
    this.relations = const {},
    this.booleanFields = const {},
  });

  final String title;
  final String entity;
  final Map<String, String> fields;
  final Map<String, RelationConfig> relations;
  final Set<String> booleanFields;

  @override
  ConsumerState<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends ConsumerState<CrudPage> {
  String _query = '';
  bool _syncing = false;

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await ref.read(repoProvider).syncEntity(widget.entity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.title} synchronisé avec succès.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de synchronisation : $error')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadRelation(RelationConfig config) async {
    final rows = await Supabase.instance.client.from(config.table).select();
    final result = List<Map<String, dynamic>>.from(rows);
    result.sort((a, b) => _relationLabel(a, config)
        .toLowerCase()
        .compareTo(_relationLabel(b, config).toLowerCase()));
    return result;
  }

  String _relationLabel(Map<String, dynamic> row, RelationConfig config) {
    for (final key in config.labelFields) {
      final value = row[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return row['id']?.toString() ?? 'Sans libellé';
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    final controllers = <String, TextEditingController>{};
    final boolValues = <String, bool>{};
    final relationValues = <String, String?>{};
    final relationOptions = <String, List<Map<String, dynamic>>>{};

    for (final field in widget.fields.keys) {
      if (widget.booleanFields.contains(field)) {
        final value = row?[field];
        boolValues[field] = value == true || value == 1 || value == 'true';
      } else if (widget.relations.containsKey(field)) {
        relationValues[field] = row?[field]?.toString();
      } else {
        controllers[field] = TextEditingController(
          text: row?[field]?.toString() ?? '',
        );
      }
    }

    try {
      for (final entry in widget.relations.entries) {
        relationOptions[entry.key] = await _loadRelation(entry.value);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chargement des listes impossible : $error')),
      );
      for (final controller in controllers.values) {
        controller.dispose();
      }
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(row == null ? 'Ajouter ${widget.title}' : 'Modifier'),
          content: SizedBox(
            width: 620,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final field in widget.fields.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: widget.booleanFields.contains(field.key)
                        ? SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(field.value),
                            value: boolValues[field.key] ?? false,
                            onChanged: (value) => setDialogState(
                              () => boolValues[field.key] = value,
                            ),
                          )
                        : widget.relations.containsKey(field.key)
                            ? DropdownButtonFormField<String>(
                                value: relationValues[field.key],
                                isExpanded: true,
                                decoration:
                                    InputDecoration(labelText: field.value),
                                items: (relationOptions[field.key] ?? [])
                                    .map(
                                      (item) => DropdownMenuItem<String>(
                                        value: item['id'].toString(),
                                        child: Text(
                                          _relationLabel(
                                            item,
                                            widget.relations[field.key]!,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => setDialogState(
                                  () => relationValues[field.key] = value,
                                ),
                              )
                            : TextField(
                                controller: controllers[field.key],
                                decoration:
                                    InputDecoration(labelText: field.value),
                              ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    try {
      if (confirmed != true) return;
      final values = <String, dynamic>{};
      for (final field in widget.fields.keys) {
        if (widget.booleanFields.contains(field)) {
          values[field] = boolValues[field] ?? false;
        } else if (widget.relations.containsKey(field)) {
          values[field] = relationValues[field];
        } else {
          values[field] = controllers[field]!.text.trim();
        }
      }
      await ref.read(repoProvider).save(
            widget.entity,
            values,
            id: row?['id']?.toString(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enregistrement effectué.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enregistrement impossible : $error')),
      );
    } finally {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
  }

  Future<void> _remove(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet élément ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(repoProvider).remove(widget.entity, row);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression impossible : $error')),
      );
    }
  }

  String _initial(Map<String, dynamic> row) {
    final value = (row['nom'] ?? row['libelle'] ?? row['code'] ?? '?')
        .toString()
        .trim();
    return value.isEmpty ? '?' : value.substring(0, 1).toUpperCase();
  }

  String _title(Map<String, dynamic> row) =>
      (row['nom'] ?? row['libelle'] ?? row['code'] ?? row['id'] ?? 'Sans titre')
          .toString();

  String _subtitle(Map<String, dynamic> row) => widget.fields.entries
      .where((entry) => row[entry.key] != null && '$row'.isNotEmpty)
      .map((entry) => '${entry.value} : ${row[entry.key]}')
      .join('  •  ');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Rechercher dans ${widget.title}',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _syncing ? null : _sync,
                icon: _syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: const Text('Synchroniser'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _edit,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref.read(repoProvider).watch(widget.entity),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur locale : ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snapshot.data!
                    .where((row) => row.values
                        .join(' ')
                        .toLowerCase()
                        .contains(_query))
                    .toList();
                if (rows.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune donnée locale. Cliquez sur Synchroniser ou Ajouter.',
                    ),
                  );
                }
                return Card(
                  child: ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final status = row['_sync_status']?.toString() ?? 'local';
                      return ListTile(
                        leading: CircleAvatar(child: Text(_initial(row))),
                        title: Text(
                          _title(row),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _subtitle(row),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              avatar: Icon(
                                status == 'synced'
                                    ? Icons.cloud_done_outlined
                                    : status == 'error'
                                        ? Icons.cloud_off_outlined
                                        : Icons.cloud_upload_outlined,
                                size: 16,
                              ),
                              label: Text(status),
                            ),
                            IconButton(
                              tooltip: 'Modifier',
                              onPressed: () => _edit(row),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              onPressed: () => _remove(row),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
