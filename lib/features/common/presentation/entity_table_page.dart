import 'package:flutter/material.dart';

import '../../../core/widgets/pro_widgets.dart';

class EntityTablePage extends StatefulWidget {
  const EntityTablePage({
    required this.title,
    required this.subtitle,
    required this.addLabel,
    required this.columns,
    required this.initialRows,
    this.statusColumn,
    this.onPrimaryAction,
    super.key,
  });

  final String title;
  final String subtitle;
  final String addLabel;
  final List<String> columns;
  final List<List<String>> initialRows;
  final int? statusColumn;
  final VoidCallback? onPrimaryAction;

  @override
  State<EntityTablePage> createState() => _EntityTablePageState();
}

class _EntityTablePageState extends State<EntityTablePage> {
  final search = TextEditingController();
  late List<List<String>> rows;

  @override
  void initState() {
    super.initState();
    rows = widget.initialRows.map((e) => List<String>.from(e)).toList();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> add() async {
    if (widget.onPrimaryAction != null) {
      widget.onPrimaryAction!();
      return;
    }

    final controllers = widget.columns
        .take(4)
        .map((_) => TextEditingController())
        .toList();

    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.addLabel),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < controllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: controllers[i],
                    decoration: InputDecoration(labelText: widget.columns[i]),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controllers
                  .map((e) => e.text.trim().isEmpty ? 'N/A' : e.text.trim())
                  .toList(),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    for (final controller in controllers) {
      controller.dispose();
    }

    if (result != null && mounted) {
      setState(
        () => rows.insert(
          0,
          [
            ...result,
            ...List.filled(widget.columns.length - result.length, 'N/A'),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.toLowerCase();
    final visible = rows
        .where((r) => r.join(' ').toLowerCase().contains(query))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeader(
          title: widget.title,
          subtitle: widget.subtitle,
          actions: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined),
              label: const Text('Exporter'),
            ),
            FilledButton.icon(
              onPressed: add,
              icon: const Icon(Icons.add),
              label: Text(widget.addLabel),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SearchToolbar(
          controller: search,
          onChanged: (_) => setState(() {}),
          extra: [
            IconButton.filledTonal(
              onPressed: () => setState(search.clear),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: visible.isEmpty
              ? const EmptyState(label: 'Aucun résultat')
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      ...widget.columns.map(
                        (c) => DataColumn(label: Text(c)),
                      ),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows: visible
                        .map(
                          (r) => DataRow(
                            cells: [
                              for (int i = 0; i < r.length; i++)
                                DataCell(
                                  widget.statusColumn == i
                                      ? StatusPill(r[i])
                                      : Text(r[i]),
                                ),
                              DataCell(
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      setState(() => rows.remove(r));
                                      return;
                                    }
                                    if (value == 'edit') {
                                      _editRow(r);
                                      return;
                                    }
                                    _showDetails(context, r);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'view',
                                      child: Text('Voir les détails'),
                                    ),
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Modifier'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Suppression logique'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _editRow(List<String> row) async {
    final controllers = <TextEditingController>[
      for (int i = 0; i < widget.columns.length; i++)
        TextEditingController(text: i < row.length ? row[i] : ''),
    ];

    final result = await showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Modifier — ${widget.title}'),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (int i = 0; i < controllers.length; i++)
                  SizedBox(
                    width: 310,
                    child: TextFormField(
                      controller: controllers[i],
                      decoration: InputDecoration(labelText: widget.columns[i]),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(
              dialogContext,
              controllers.map((controller) => controller.text.trim()).toList(),
            ),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    for (final controller in controllers) {
      controller.dispose();
    }

    if (result != null && mounted) {
      setState(() {
        final index = rows.indexOf(row);
        if (index >= 0) rows[index] = result;
      });
    }
  }

  Future<void> _showDetails(BuildContext context, List<String> row) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < widget.columns.length; i++)
                  ListTile(
                    dense: true,
                    title: Text(
                      widget.columns[i],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(i < row.length ? row[i] : 'N/A'),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
