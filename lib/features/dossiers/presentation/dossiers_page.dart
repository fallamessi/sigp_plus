import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/pro_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/dossier_repository.dart';
import '../domain/dossier.dart';

final dossierRepositoryProvider = Provider<DossierRepository>(
  (ref) => DossierRepository(ref.watch(apiClientProvider)),
);

class DossiersPage extends ConsumerStatefulWidget {
  const DossiersPage({super.key});

  @override
  ConsumerState<DossiersPage> createState() => _DossiersPageState();
}

class _DossiersPageState extends ConsumerState<DossiersPage> {
  final search = TextEditingController();
  String status = 'Tous';
  bool loading = true;
  String? error;
  List<Dossier> rows = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await ref.read(dossierRepositoryProvider).list(
            search: search.text,
            status: status,
          );
      if (!mounted) return;
      setState(() => rows = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'Impossible de charger les dossiers.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _delete(Dossier dossier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le dossier'),
        content: Text(
          'Confirmer la suppression logique du dossier ${dossier.numero} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(dossierRepositoryProvider).delete(dossier.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dossier supprimé avec succès.')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeader(
          title: 'Dossiers de pension',
          subtitle:
              'Données sécurisées chargées depuis le backend PHP/PostgreSQL.',
          actions: [
            OutlinedButton.icon(
              onPressed: loading ? null : _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
            FilledButton.icon(
              onPressed: () => _showCreateInfo(context),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau dossier'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SearchToolbar(
          controller: search,
          onChanged: (_) {},
          extra: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: const [
                  'Tous',
                  'CREE',
                  'EN_COURS_TRAITEMENT',
                  'EN_ATTENTE_COMPLEMENT',
                  'REJETE',
                  'VALIDE',
                  'LIQUIDE',
                ]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.replaceAll('_', ' ')),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => status = value ?? 'Tous');
                  _load();
                },
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: loading ? null : _load,
              icon: const Icon(Icons.search),
              label: const Text('Rechercher'),
            ),
            IconButton.filledTonal(
              onPressed: () {
                search.clear();
                setState(() => status = 'Tous');
                _load();
              },
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (loading)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (error != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.cloud_off, size: 48),
                  const SizedBox(height: 12),
                  Text(error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          )
        else if (rows.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('Aucun dossier trouvé.')),
            ),
          )
        else
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('N° DOSSIER')),
                  DataColumn(label: Text('ASSURÉ')),
                  DataColumn(label: Text('TYPE')),
                  DataColumn(label: Text('STATUT')),
                  DataColumn(label: Text('PRIORITÉ')),
                  DataColumn(label: Text('SERVICE')),
                  DataColumn(label: Text('CRÉATION')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: rows
                    .map(
                      (dossier) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              dossier.numero,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          DataCell(Text(dossier.assure)),
                          DataCell(Text(dossier.typeDossier)),
                          DataCell(StatusPill(dossier.statut)),
                          DataCell(StatusPill(dossier.priorite)),
                          DataCell(Text(dossier.service)),
                          DataCell(Text(_formatDate(dossier.createdAt))),
                          DataCell(
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'view') {
                                  _details(context, dossier);
                                } else if (value == 'delete') {
                                  _delete(dossier);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Text('Voir les détails'),
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

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  void _details(BuildContext context, Dossier dossier) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(dossier.numero),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detail('Assuré', dossier.assure),
              _detail('Type', dossier.typeDossier),
              _detail('Statut', dossier.statut),
              _detail('Priorité', dossier.priorite),
              _detail('Service', dossier.service),
              _detail('Création', _formatDate(dossier.createdAt)),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => ListTile(
        dense: true,
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      );

  void _showCreateInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Création sécurisée'),
        content: const Text(
          'L’endpoint POST /api/dossiers est prêt. Le formulaire devra charger '
          'les assurés et types de dossier depuis leurs référentiels avant envoi.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}
