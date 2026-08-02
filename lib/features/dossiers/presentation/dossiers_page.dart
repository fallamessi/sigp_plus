import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/pro_widgets.dart';
import '../../../core/database/local_database.dart';
import '../../../core/providers/supabase_provider.dart';
import '../data/dossier_repository.dart';
import '../domain/dossier.dart';

/// Dépôt utilisé par la page des dossiers.
///
final dossierRepositoryProvider = Provider<DossierRepository>((ref) {
  return DossierRepository(
    ref.watch(supabaseClientProvider),
    LocalDatabase.instance,
  );
});

class DossiersPage extends ConsumerStatefulWidget {
  const DossiersPage({super.key});

  @override
  ConsumerState<DossiersPage> createState() {
    return _DossiersPageState();
  }
}

class _DossiersPageState extends ConsumerState<DossiersPage> {
  final TextEditingController _searchController =
  TextEditingController();

  Timer? _searchDebounce;

  String _selectedStatus = 'Tous';
  bool _isLoading = true;
  String? _errorMessage;
  List<Dossier> _dossiers = const [];

  static const List<String> _statuses = [
    'Tous',
    'CREE',
    'EN_COURS_TRAITEMENT',
    'EN_ATTENTE_COMPLEMENT',
    'REJETE',
    'VALIDE',
    'LIQUIDE',
    'ARCHIVE',
  ];

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(_loadDossiers);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Charge les dossiers depuis le dépôt.
  Future<void> _loadDossiers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(
        dossierRepositoryProvider,
      );

      final result = await repository.list(
        search: _searchController.text.trim(),
        status: _selectedStatus,
      );

      if (!mounted) return;

      setState(() {
        _dossiers = result;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
        'Impossible de charger les dossiers : $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Lance automatiquement la recherche après la saisie.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      _loadDossiers,
    );
  }

  void _resetFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();

    setState(() {
      _selectedStatus = 'Tous';
    });

    _loadDossiers();
  }

  Future<void> _deleteDossier(
      Dossier dossier,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le dossier'),
          content: Text(
            'Voulez-vous vraiment effectuer la suppression '
                'logique du dossier ${dossier.numero} ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(dossierRepositoryProvider)
          .delete(dossier.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le dossier ${dossier.numero} a été supprimé.',
          ),
        ),
      );

      await _loadDossiers();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur pendant la suppression : $error',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDossiers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          PageHeader(
            title: 'Dossiers de pension',
            subtitle:
            'Gestion, suivi et traitement des dossiers de pension.',
            actions: [
              OutlinedButton.icon(
                onPressed:
                _isLoading ? null : _loadDossiers,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualiser'),
              ),
              FilledButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nouveau dossier'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchToolbar(),
          const SizedBox(height: 16),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildSearchToolbar() {
    return SearchToolbar(
      controller: _searchController,
      onChanged: _onSearchChanged,
      extra: [
        SizedBox(
          width: 230,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Statut',
              prefixIcon: Icon(Icons.filter_alt_outlined),
            ),
            items: _statuses.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(
                  _displayStatus(status),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _isLoading
                ? null
                : (value) {
              if (value == null) return;

              setState(() {
                _selectedStatus = value;
              });

              _loadDossiers();
            },
          ),
        ),
        FilledButton.tonalIcon(
          onPressed:
          _isLoading ? null : _loadDossiers,
          icon: const Icon(Icons.search),
          label: const Text('Rechercher'),
        ),
        Tooltip(
          message: 'Réinitialiser les filtres',
          child: IconButton.filledTonal(
            onPressed:
            _isLoading ? null : _resetFilters,
            icon: const Icon(Icons.restart_alt),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement des dossiers...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 54,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 14),
              Text(
                'Chargement impossible',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _loadDossiers,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_dossiers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              const Icon(
                Icons.folder_off_outlined,
                size: 54,
              ),
              const SizedBox(height: 14),
              Text(
                'Aucun dossier trouvé',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Modifiez les critères de recherche ou créez '
                    'un nouveau dossier.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Créer un dossier'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildDossiersTable();
  }

  Widget _buildDossiersTable() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              12,
            ),
            child: Row(
              children: [
                Text(
                  '${_dossiers.length} dossier(s)',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _selectedStatus == 'Tous'
                      ? 'Tous les statuts'
                      : _displayStatus(_selectedStatus),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              columns: const [
                DataColumn(
                  label: Text('N° DOSSIER'),
                ),
                DataColumn(
                  label: Text('ASSURÉ'),
                ),
                DataColumn(
                  label: Text('TYPE'),
                ),
                DataColumn(
                  label: Text('STATUT'),
                ),
                DataColumn(
                  label: Text('PRIORITÉ'),
                ),
                DataColumn(
                  label: Text('SERVICE'),
                ),
                DataColumn(
                  label: Text('CRÉATION'),
                ),
                DataColumn(
                  label: Text('ACTIONS'),
                ),
              ],
              rows: _dossiers.map((dossier) {
                return DataRow(
                  onSelectChanged: (_) {
                    _showDossierDetails(dossier);
                  },
                  cells: [
                    DataCell(
                      Text(
                        dossier.numero,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 180,
                        child: Text(
                          dossier.assure,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        dossier.typeDossier,
                      ),
                    ),
                    DataCell(
                      StatusPill(dossier.statut),
                    ),
                    DataCell(
                      StatusPill(dossier.priorite),
                    ),
                    DataCell(
                      Text(dossier.service),
                    ),
                    DataCell(
                      Text(
                        _formatDate(dossier.createdAt),
                      ),
                    ),
                    DataCell(
                      PopupMenuButton<_DossierAction>(
                        tooltip: 'Actions',
                        onSelected: (action) {
                          switch (action) {
                            case _DossierAction.view:
                              _showDossierDetails(dossier);
                              break;

                            case _DossierAction.edit:
                              _showEditInfo(dossier);
                              break;

                            case _DossierAction.delete:
                              _deleteDossier(dossier);
                              break;
                          }
                        },
                        itemBuilder: (context) {
                          return const [
                            PopupMenuItem(
                              value: _DossierAction.view,
                              child: ListTile(
                                leading: Icon(
                                  Icons.visibility_outlined,
                                ),
                                title: Text(
                                  'Voir les détails',
                                ),
                                contentPadding:
                                EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: _DossierAction.edit,
                              child: ListTile(
                                leading: Icon(
                                  Icons.edit_outlined,
                                ),
                                title: Text(
                                  'Modifier',
                                ),
                                contentPadding:
                                EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuDivider(),
                            PopupMenuItem(
                              value: _DossierAction.delete,
                              child: ListTile(
                                leading: Icon(
                                  Icons.delete_outline,
                                ),
                                title: Text(
                                  'Suppression logique',
                                ),
                                contentPadding:
                                EdgeInsets.zero,
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    final localDate = date.toLocal();

    final day = localDate.day
        .toString()
        .padLeft(2, '0');

    final month = localDate.month
        .toString()
        .padLeft(2, '0');

    return '$day/$month/${localDate.year}';
  }

  String _displayStatus(String status) {
    if (status == 'Tous') {
      return status;
    }

    return status
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) {
      if (word.isEmpty) return word;

      return '${word[0].toUpperCase()}'
          '${word.substring(1)}';
    })
        .join(' ');
  }

  void _showDossierDetails(
      Dossier dossier,
      ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.folder_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(dossier.numero),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailTile(
                    'Assuré',
                    dossier.assure,
                    Icons.person_outline,
                  ),
                  _buildDetailTile(
                    'Type de dossier',
                    dossier.typeDossier,
                    Icons.category_outlined,
                  ),
                  _buildDetailTile(
                    'Statut',
                    _displayStatus(dossier.statut),
                    Icons.flag_outlined,
                  ),
                  _buildDetailTile(
                    'Priorité',
                    dossier.priorite,
                    Icons.priority_high,
                  ),
                  _buildDetailTile(
                    'Service responsable',
                    dossier.service,
                    Icons.business_center_outlined,
                  ),
                  _buildDetailTile(
                    'Date de création',
                    _formatDate(dossier.createdAt),
                    Icons.calendar_today_outlined,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showEditInfo(dossier);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailTile(
      String label,
      String value,
      IconData icon,
      ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Icon(icon),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        value.trim().isEmpty ? '-' : value,
      ),
    );
  }

  void _showCreateDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nouveau dossier'),
          content: const SizedBox(
            width: 520,
            child: Text(
              'Le formulaire de création devra charger les '
                  'types de dossier, les agences et les personnes '
                  'depuis les référentiels Supabase.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _showEditInfo(
      Dossier dossier,
      ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Modifier ${dossier.numero}',
          ),
          content: const SizedBox(
            width: 520,
            child: Text(
              'Le formulaire de modification sera connecté '
                  'à la méthode PATCH du dépôt des dossiers.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}

enum _DossierAction {
  view,
  edit,
  delete,
}