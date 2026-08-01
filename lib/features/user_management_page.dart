import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  bool _loading = true;
  String _query = '';
  String? _error;
  List<Map<String, dynamic>> _users = const [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _supabase
          .from('utilisateurs')
          .select('*, roles(nom), agences(nom), services(nom)')
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() => _users = List<Map<String, dynamic>>.from(rows));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les utilisateurs : $error';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadOptions(String table) async {
    final rows = await _supabase.from(table).select().order('nom');
    return List<Map<String, dynamic>>.from(rows);
  }

  String _labelOf(Map<String, dynamic> item) {
    for (final key in const ['nom', 'libelle', 'code', 'email']) {
      final value = item[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return item['id']?.toString() ?? 'Sans libellé';
  }

  Future<void> _openCreateDialog() async {
    List<Map<String, dynamic>> roles;
    List<Map<String, dynamic>> agences;
    List<Map<String, dynamic>> services;

    try {
      final values = await Future.wait([
        _loadOptions('roles'),
        _loadOptions('agences'),
        _loadOptions('services'),
      ]);
      roles = values[0];
      agences = values[1];
      services = values[2];
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chargement des listes impossible : $error')),
      );
      return;
    }

    if (!mounted) return;
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateUserDialog(
        roles: roles,
        agences: agences,
        services: services,
        labelOf: _labelOf,
      ),
    );

    if (created == true) await _loadUsers();
  }

  Future<void> _toggleActive(Map<String, dynamic> user, bool active) async {
    try {
      await _supabase
          .from('utilisateurs')
          .update({'actif': active}).eq('id', user['id']);
      await _loadUsers();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mise à jour impossible : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((user) {
      if (_query.isEmpty) return true;
      return user.values.join(' ').toLowerCase().contains(_query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(
                    () => _query = value.trim().toLowerCase(),
                  ),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Rechercher un utilisateur',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualiser'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Créer un compte'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_error!)),
                  ],
                ),
              ),
            ),
          if (_error != null) const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('Aucun utilisateur trouvé.'))
                    : Card(
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Utilisateur')),
                              DataColumn(label: Text('E-mail')),
                              DataColumn(label: Text('Rôle')),
                              DataColumn(label: Text('Agence')),
                              DataColumn(label: Text('Service')),
                              DataColumn(label: Text('Statut')),
                            ],
                            rows: filtered.map((user) {
                              final name = [user['prenom'], user['nom']]
                                  .where((v) => v != null && '$v'.isNotEmpty)
                                  .join(' ');
                              final active = user['actif'] != false;
                              return DataRow(
                                cells: [
                                  DataCell(Text(name.isEmpty ? '—' : name)),
                                  DataCell(Text(user['email']?.toString() ?? '—')),
                                  DataCell(Text(
                                      (user['roles'] as Map?)?['nom']?.toString() ??
                                          '—')),
                                  DataCell(Text((user['agences'] as Map?)?['nom']
                                          ?.toString() ??
                                      '—')),
                                  DataCell(Text((user['services'] as Map?)?['nom']
                                          ?.toString() ??
                                      '—')),
                                  DataCell(
                                    Switch(
                                      value: active,
                                      onChanged: (value) =>
                                          _toggleActive(user, value),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog({
    required this.roles,
    required this.agences,
    required this.services,
    required this.labelOf,
  });

  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> agences;
  final List<Map<String, dynamic>> services;
  final String Function(Map<String, dynamic>) labelOf;

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _email = TextEditingController();
  final _telephone = TextEditingController();
  final _password = TextEditingController();

  String? _roleId;
  String? _agenceId;
  String? _serviceId;
  bool _active = true;
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nom.dispose();
    _prenom.dispose();
    _email.dispose();
    _telephone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-user',
        body: {
          'email': _email.text.trim(),
          'password': _password.text,
          'nom': _nom.text.trim(),
          'prenom': _prenom.text.trim(),
          'telephone': _telephone.text.trim(),
          'role_id': _roleId,
          'agence_id': _agenceId,
          'service_id': _serviceId,
          'actif': _active,
        },
      );

      if (response.status < 200 || response.status >= 300) {
        throw Exception(response.data?.toString() ?? 'Création refusée.');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte utilisateur créé avec succès.')),
      );
    } on FunctionException catch (error) {
      setState(() {
        _error = error.details?.toString() ??
            'La fonction sécurisée create-user est indisponible.';
      });
    } catch (error) {
      setState(() => _error = 'Création du compte impossible : $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer un compte utilisateur'),
      content: SizedBox(
        width: 680,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prenom,
                        decoration:
                            const InputDecoration(labelText: 'Prénom'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nom,
                        decoration: const InputDecoration(labelText: 'Nom *'),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Nom obligatoire.'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(labelText: 'Adresse e-mail *'),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return 'Adresse e-mail obligatoire.';
                    if (!email.contains('@')) return 'Adresse e-mail invalide.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _telephone,
                        decoration:
                            const InputDecoration(labelText: 'Téléphone'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe initial *',
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: (value) => (value ?? '').length < 8
                            ? 'Au moins 8 caractères.'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _roleId,
                        decoration: const InputDecoration(labelText: 'Rôle *'),
                        items: widget.roles
                            .map((item) => DropdownMenuItem(
                                  value: item['id'].toString(),
                                  child: Text(widget.labelOf(item)),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _roleId = value),
                        validator: (value) => value == null
                            ? 'Sélectionnez un rôle.'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _agenceId,
                        decoration: const InputDecoration(labelText: 'Agence'),
                        items: widget.agences
                            .map((item) => DropdownMenuItem(
                                  value: item['id'].toString(),
                                  child: Text(widget.labelOf(item)),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _agenceId = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _serviceId,
                  decoration: const InputDecoration(labelText: 'Service'),
                  items: widget.services
                      .map((item) => DropdownMenuItem(
                            value: item['id'].toString(),
                            child: Text(widget.labelOf(item)),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _serviceId = value),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compte actif'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
                if (_error != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add),
          label: const Text('Créer le compte'),
        ),
      ],
    );
  }
}
