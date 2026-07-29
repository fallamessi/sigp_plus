import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/network/api_client.dart';

class CrudPage extends ConsumerStatefulWidget {
  const CrudPage(
      {super.key,
      required this.title,
      required this.endpoint,
      required this.fields});
  final String title, endpoint;
  final List<String> fields;
  @override
  ConsumerState<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends ConsumerState<CrudPage> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  String? error;
  final search = TextEditingController();
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final r = await ref.read(apiClientProvider).request(
          '${widget.endpoint}?search=${Uri.encodeQueryComponent(search.text)}');
      rows = List<Map<String, dynamic>>.from(r['data'] as List);
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> form([Map<String, dynamic>? item]) async {
    final ctrls = {
      for (final f in widget.fields)
        f: TextEditingController(text: item?[f]?.toString() ?? '')
    };
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(item == null ? 'Ajouter' : 'Modifier'),
                content: SizedBox(
                    width: 500,
                    child: ListView(shrinkWrap: true, children: [
                      for (final f in widget.fields)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                                controller: ctrls[f],
                                decoration: InputDecoration(
                                    labelText: f.replaceAll('_', ' '))))
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Annuler')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Enregistrer'))
                ]));
    if (ok == true) {
      final body = {for (final e in ctrls.entries) e.key: e.value.text};
      await ref.read(apiClientProvider).request(
          item == null ? widget.endpoint : '${widget.endpoint}/${item['id']}',
          method: item == null ? 'POST' : 'PUT',
          body: body);
      await load();
    }
  }

  Future<void> remove(Map<String, dynamic> item) async {
    await ref
        .read(apiClientProvider)
        .request('${widget.endpoint}/${item['id']}', method: 'DELETE');
    await load();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: TextField(
                  controller: search,
                  onSubmitted: (_) => load(),
                  decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Rechercher dans ${widget.title}'))),
          const SizedBox(width: 12),
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
          FilledButton.icon(
              onPressed: () => form(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'))
        ]),
        const SizedBox(height: 16),
        if (error != null)
          Text(error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                    ? const Center(child: Text('Aucune donnée'))
                    : Card(
                        child: ListView.separated(
                            itemCount: rows.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (c, i) {
                              final r = rows[i];
                              return ListTile(
                                  title: Text((r['nom'] ??
                                          r['numero_dossier'] ??
                                          r['matricule'] ??
                                          r['id'])
                                      .toString()),
                                  subtitle: Text(
                                      widget.fields
                                          .where((f) => r[f] != null)
                                          .map((f) => '$f: ${r[f]}')
                                          .join(' • '),
                                      maxLines: 2),
                                  trailing: Wrap(children: [
                                    IconButton(
                                        onPressed: () => form(r),
                                        icon: const Icon(Icons.edit)),
                                    IconButton(
                                        onPressed: () => remove(r),
                                        icon: const Icon(Icons.delete_outline))
                                  ]));
                            })))
      ]));
}
