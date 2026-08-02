import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/network/entity_repository.dart';
import '../../../core/database/local_database.dart';

enum DynamicFieldType {
  text,
  multiline,
  integer,
  decimal,
  email,
  phone,
  date,
  dateTime,
  boolean,
  select,
}

class DynamicFormField {
  const DynamicFormField({
    required this.keyName,
    this.label,
    this.type,
    this.required = false,
    this.readOnly = false,
    this.hint,
    this.options = const <String, String>{},
  });

  final String keyName;
  final String? label;
  final DynamicFieldType? type;
  final bool required;
  final bool readOnly;
  final String? hint;
  final Map<String, String> options;

  String get displayLabel => label ?? _humanize(keyName);

  DynamicFieldType get resolvedType => type ?? _inferType(keyName);

  static String _humanize(String value) {
    if (value.isEmpty) return value;
    final text = value.replaceAll('_', ' ').trim();
    return text[0].toUpperCase() + text.substring(1);
  }

  static DynamicFieldType _inferType(String key) {
    final value = key.toLowerCase();
    if (value == 'actif' ||
        value == 'lue' ||
        value == 'obligatoire' ||
        value.startsWith('est_') ||
        value.startsWith('is_')) {
      return DynamicFieldType.boolean;
    }
    if (value.contains('date') || value.endsWith('_at')) {
      return value.endsWith('_at')
          ? DynamicFieldType.dateTime
          : DynamicFieldType.date;
    }
    if (value.contains('email')) return DynamicFieldType.email;
    if (value.contains('telephone') || value.contains('phone')) {
      return DynamicFieldType.phone;
    }
    if (value.contains('montant') ||
        value.contains('score') ||
        value.contains('confiance')) {
      return DynamicFieldType.decimal;
    }
    if (value == 'ordre' ||
        value.contains('nombre') ||
        value.contains('version') ||
        value.contains('taille')) {
      return DynamicFieldType.integer;
    }
    if (value.contains('description') ||
        value.contains('commentaire') ||
        value.contains('motif') ||
        value.contains('message') ||
        value.contains('adresse') ||
        value.contains('coordonnees')) {
      return DynamicFieldType.multiline;
    }
    return DynamicFieldType.text;
  }
}

class RemoteEntityPage extends ConsumerStatefulWidget {
  const RemoteEntityPage({
    super.key,
    required this.title,
    required this.entity,
    required this.columns,
    this.fields = const <String>[],
    this.formFields,
    this.subtitle,
    this.readOnly = false,
  });

  final String title;
  final String entity;
  final String? subtitle;
  final Map<String, String> columns;
  final List<String> fields;
  final List<DynamicFormField>? formFields;
  final bool readOnly;

  List<DynamicFormField> get resolvedFields =>
      formFields ?? fields.map((field) => DynamicFormField(keyName: field)).toList();

  @override
  ConsumerState<RemoteEntityPage> createState() => _RemoteEntityPageState();
}

class _RemoteEntityPageState extends ConsumerState<RemoteEntityPage> {
  final TextEditingController search = TextEditingController();
  List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
  bool loading = true;
  String? error;

  EntityRepository get repository => EntityRepository(
    ref.read(supabaseClientProvider),
        LocalDatabase.instance,
      );

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      rows = await repository.list(widget.entity, search: search.text.trim());
    } catch (exception) {
      error = exception.toString();
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DynamicEntityDialog(
        title: widget.title,
        fields: widget.resolvedFields,
        initialData: row,
      ),
    );

    if (result == null) return;

    try {
      if (row == null) {
        await repository.create(widget.entity, result);
        _message('Enregistrement ajouté avec succès.');
      } else {
        await repository.update(widget.entity, row['id'].toString(), result);
        _message('Modifications enregistrées avec succès.');
      }
      await load();
    } catch (exception) {
      _message(exception.toString(), error: true);
    }
  }

  Future<void> _showDetails(Map<String, dynamic> row) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _EntityDetailsDialog(
        title: widget.title,
        data: row,
        preferredColumns: widget.columns,
        onEdit: widget.readOnly
            ? null
            : () {
                Navigator.of(context).pop();
                _openForm(row);
              },
      ),
    );
  }

  Future<void> _remove(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded, size: 42),
            title: const Text('Confirmer la suppression'),
            content: const Text(
              'Cet enregistrement sera supprimé. Cette opération peut être irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await repository.delete(widget.entity, row['id'].toString());
      _message('Enregistrement supprimé.');
      await load();
    } catch (exception) {
      _message(exception.toString(), error: true);
    }
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 18),
          _buildToolbar(),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle ??
                    'Consultez, recherchez et gérez les informations de ce module.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Actualiser',
          onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh),
        ),
        if (!widget.readOnly) ...[
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
        ],
      ],
    );
  }

  Widget _buildToolbar() {
    return TextField(
      controller: search,
      onSubmitted: (_) => load(),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Rechercher dans ${widget.title.toLowerCase()}...',
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (search.text.isNotEmpty)
              IconButton(
                tooltip: 'Effacer',
                onPressed: () {
                  search.clear();
                  load();
                },
                icon: const Icon(Icons.close),
              ),
            IconButton(
              tooltip: 'Lancer la recherche',
              onPressed: load,
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 52),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: load,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 56),
            const SizedBox(height: 12),
            const Text('Aucune donnée disponible'),
            if (!widget.readOnly) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Créer le premier enregistrement'),
              ),
            ],
          ],
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) => Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: [
                    ...widget.columns.values.map(
                      (label) => DataColumn(label: Text(label)),
                    ),
                    const DataColumn(label: Text('Actions')),
                  ],
                  rows: rows.map((row) {
                    return DataRow(
                      onSelectChanged: (_) => _showDetails(row),
                      cells: [
                        ...widget.columns.keys.map(
                          (key) => DataCell(
                            _ValueView(value: row[key], fieldName: key),
                          ),
                        ),
                        DataCell(
                          Wrap(
                            spacing: 2,
                            children: [
                              IconButton(
                                tooltip: 'Voir',
                                onPressed: () => _showDetails(row),
                                icon: const Icon(Icons.visibility_outlined),
                              ),
                              if (!widget.readOnly)
                                IconButton(
                                  tooltip: 'Modifier',
                                  onPressed: () => _openForm(row),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                              if (!widget.readOnly)
                                IconButton(
                                  tooltip: 'Supprimer',
                                  onPressed: () => _remove(row),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DynamicEntityDialog extends StatefulWidget {
  const _DynamicEntityDialog({
    required this.title,
    required this.fields,
    this.initialData,
  });

  final String title;
  final List<DynamicFormField> fields;
  final Map<String, dynamic>? initialData;

  @override
  State<_DynamicEntityDialog> createState() => _DynamicEntityDialogState();
}

class _DynamicEntityDialogState extends State<_DynamicEntityDialog> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  final Map<String, bool> booleanValues = {};
  final Map<String, String?> selectedValues = {};

  bool get editing => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      final raw = widget.initialData?[field.keyName];
      if (field.resolvedType == DynamicFieldType.boolean) {
        booleanValues[field.keyName] = _toBool(raw);
      } else if (field.resolvedType == DynamicFieldType.select) {
        selectedValues[field.keyName] = raw?.toString();
      } else {
        controllers[field.keyName] = TextEditingController(
          text: _editableText(raw, field.resolvedType),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Icon(editing ? Icons.edit_outlined : Icons.add),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editing ? 'Modifier' : 'Nouvel enregistrement',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(widget.title),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final itemWidth = width >= 650 ? (width - 16) / 2 : width;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: widget.fields
                            .map(
                              (field) => SizedBox(
                                width: field.resolvedType == DynamicFieldType.multiline
                                    ? width
                                    : itemWidth,
                                child: _buildField(field),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(editing ? 'Enregistrer' : 'Créer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(DynamicFormField field) {
    switch (field.resolvedType) {
      case DynamicFieldType.boolean:
        return SwitchListTile.adaptive(
          value: booleanValues[field.keyName] ?? false,
          onChanged: field.readOnly
              ? null
              : (value) => setState(() => booleanValues[field.keyName] = value),
          title: Text(field.displayLabel),
          subtitle: Text((booleanValues[field.keyName] ?? false) ? 'Oui' : 'Non'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      case DynamicFieldType.select:
        return DropdownButtonFormField<String>(
          value: selectedValues[field.keyName],
          decoration: InputDecoration(labelText: field.displayLabel),
          items: field.options.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: field.readOnly
              ? null
              : (value) => setState(() => selectedValues[field.keyName] = value),
          validator: (value) => field.required && (value == null || value.isEmpty)
              ? '${field.displayLabel} est obligatoire.'
              : null,
        );
      default:
        final controller = controllers[field.keyName]!;
        return TextFormField(
          controller: controller,
          readOnly: field.readOnly ||
              field.resolvedType == DynamicFieldType.date ||
              field.resolvedType == DynamicFieldType.dateTime,
          maxLines: field.resolvedType == DynamicFieldType.multiline ? 4 : 1,
          minLines: field.resolvedType == DynamicFieldType.multiline ? 3 : 1,
          keyboardType: _keyboard(field.resolvedType),
          inputFormatters: _formatters(field.resolvedType),
          onTap: field.readOnly ? null : () => _pickDate(field, controller),
          decoration: InputDecoration(
            labelText: field.displayLabel,
            hintText: field.hint,
            suffixIcon: field.resolvedType == DynamicFieldType.date ||
                    field.resolvedType == DynamicFieldType.dateTime
                ? const Icon(Icons.calendar_today_outlined)
                : null,
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (field.required && text.isEmpty) {
              return '${field.displayLabel} est obligatoire.';
            }
            if (text.isNotEmpty && field.resolvedType == DynamicFieldType.email) {
              final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
              if (!valid) return 'Adresse e-mail invalide.';
            }
            return null;
          },
        );
    }
  }

  Future<void> _pickDate(
    DynamicFormField field,
    TextEditingController controller,
  ) async {
    if (field.resolvedType != DynamicFieldType.date &&
        field.resolvedType != DynamicFieldType.dateTime) {
      return;
    }

    final parsed = DateTime.tryParse(controller.text);
    final date = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    if (field.resolvedType == DynamicFieldType.dateTime) {
      final time = await showTimePicker(
        context: context,
        initialTime: parsed == null
            ? TimeOfDay.now()
            : TimeOfDay(hour: parsed.hour, minute: parsed.minute),
      );
      if (time == null) return;
      controller.text = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ).toIso8601String();
    } else {
      controller.text =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  void _submit() {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final data = <String, dynamic>{};
    for (final field in widget.fields) {
      switch (field.resolvedType) {
        case DynamicFieldType.boolean:
          data[field.keyName] = booleanValues[field.keyName] ?? false;
          break;
        case DynamicFieldType.select:
          data[field.keyName] = selectedValues[field.keyName];
          break;
        case DynamicFieldType.integer:
          final text = controllers[field.keyName]!.text.trim();
          data[field.keyName] = text.isEmpty ? null : int.tryParse(text);
          break;
        case DynamicFieldType.decimal:
          final text = controllers[field.keyName]!.text.trim().replaceAll(',', '.');
          data[field.keyName] = text.isEmpty ? null : double.tryParse(text);
          break;
        default:
          final text = controllers[field.keyName]!.text.trim();
          data[field.keyName] = text.isEmpty ? null : text;
      }
    }

    Navigator.pop(context, data);
  }

  static TextInputType _keyboard(DynamicFieldType type) {
    switch (type) {
      case DynamicFieldType.integer:
        return TextInputType.number;
      case DynamicFieldType.decimal:
        return const TextInputType.numberWithOptions(decimal: true);
      case DynamicFieldType.email:
        return TextInputType.emailAddress;
      case DynamicFieldType.phone:
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }

  static List<TextInputFormatter> _formatters(DynamicFieldType type) {
    switch (type) {
      case DynamicFieldType.integer:
        return <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly];
      case DynamicFieldType.decimal:
        return <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*$')),
        ];
      default:
        return const <TextInputFormatter>[];
    }
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().toLowerCase().trim();
    return text == 'true' || text == '1' || text == 'oui';
  }

  static String _editableText(dynamic value, DynamicFieldType type) {
    if (value == null) return '';
    if (value is Map || value is List) return value.toString();
    final text = value.toString();
    if (type == DynamicFieldType.date && text.length >= 10) {
      return text.substring(0, 10);
    }
    return text;
  }
}

class _EntityDetailsDialog extends StatelessWidget {
  const _EntityDetailsDialog({
    required this.title,
    required this.data,
    required this.preferredColumns,
    this.onEdit,
  });

  final String title;
  final Map<String, dynamic> data;
  final Map<String, String> preferredColumns;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final orderedKeys = <String>[
      ...preferredColumns.keys,
      ...data.keys.where((key) => !preferredColumns.containsKey(key)),
    ];

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.visibility_outlined)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Détails — $title',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: orderedKeys.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final key = orderedKeys[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(
                      preferredColumns[key] ?? DynamicFormField._humanize(key),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: _ValueView(value: data[key], fieldName: key),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueView extends StatelessWidget {
  const _ValueView({required this.value, required this.fieldName});

  final dynamic value;
  final String fieldName;

  @override
  Widget build(BuildContext context) {
    if (value == null || value.toString().trim().isEmpty) {
      return Text(
        '—',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    if (value is bool || _looksBoolean(fieldName)) {
      final active = value == true || value.toString().toLowerCase() == 'true';
      return Chip(
        visualDensity: VisualDensity.compact,
        avatar: Icon(active ? Icons.check_circle : Icons.cancel, size: 17),
        label: Text(active ? 'Oui' : 'Non'),
      );
    }

    if (value is Map) {
      final label = value['nom'] ?? value['libelle'] ?? value['code'] ?? value['id'];
      return Text(label?.toString() ?? value.toString());
    }

    if (value is List) {
      return Text(value.map((item) => item.toString()).join(', '));
    }

    return SelectableText(value.toString());
  }

  static bool _looksBoolean(String field) {
    final key = field.toLowerCase();
    return key == 'actif' || key == 'lue' || key == 'obligatoire';
  }
}
