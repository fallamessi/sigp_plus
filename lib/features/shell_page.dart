import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'configuration_page.dart';
import 'crud_page.dart';
import 'login_page.dart';
import 'user_management_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int index = 0;

  final items = const [
    ('Tableau de bord', Icons.dashboard_outlined),
    ('Agences', Icons.business_outlined),
    ('Services', Icons.account_tree_outlined),
    ('Personnes', Icons.people_outline),
    ('Dossiers', Icons.folder_outlined),
    ('Documents', Icons.description_outlined),
    ('Notifications', Icons.notifications_outlined),
    ('Audit', Icons.history_outlined),
    ('Utilisateurs', Icons.manage_accounts_outlined),
    ('Configuration', Icons.settings_outlined),
  ];

  Widget page() {
    return switch (index) {
      0 => const Dashboard(),
      1 => const CrudPage(
          title: 'Agences',
          entity: 'agences',
          fields: {
            'code': 'Code',
            'nom': 'Nom',
          },
        ),
      2 => const CrudPage(
          title: 'Services',
          entity: 'services',
          fields: {
            'code': 'Code',
            'nom': 'Nom',
          },
        ),
      3 => const CrudPage(
          title: 'Personnes',
          entity: 'personnes',
          fields: {
            'matricule': 'Matricule',
            'titre': 'Titre',
            'nom': 'Nom',
            'prenom': 'Prénom',
            'telephone': 'Téléphone',
            'email': 'E-mail',
          },
        ),
      4 => const CrudPage(
          title: 'Dossiers',
          entity: 'dossiers',
          fields: {
            'numero_dossier': 'Numéro',
            'ref_ged': 'Référence GED',
            'statut_courant': 'Statut',
          },
        ),
      5 => const CrudPage(
          title: 'Documents',
          entity: 'documents',
          fields: {
            'nom_fichier': 'Nom du fichier',
            'mime_type': 'Type MIME',
            'storage_path': 'Chemin Storage',
          },
        ),
      6 => const CrudPage(
          title: 'Notifications',
          entity: 'notifications',
          fields: {
            'type_notification': 'Type',
            'message': 'Message',
          },
        ),
      7 => const CrudPage(
          title: 'Journal d’audit',
          entity: 'audit_log',
          fields: {
            'entite': 'Entité',
            'action': 'Action',
          },
        ),
      8 => const UserManagementPage(),
      _ => const ConfigurationPage(),
    };
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: const Color(0xFF073E2D),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 34,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'SIGP+',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, itemIndex) {
                      final item = items[itemIndex];

                      return ListTile(
                        selected: itemIndex == index,
                        selectedTileColor: Colors.white12,
                        leading: Icon(
                          item.$2,
                          color: Colors.white70,
                        ),
                        title: Text(
                          item.$1,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            index = itemIndex;
                          });
                        },
                      );
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'Déconnexion',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onTap: _logout,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(
                        items[index].$1,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.circle,
                        color: Colors.green,
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Mode connecté / offline-first',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: page(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.count(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.55,
        children: const [
          _Kpi(
            'Dossiers actifs',
            '0',
            Icons.folder_open,
          ),
          _Kpi(
            'En traitement',
            '0',
            Icons.pending_actions,
          ),
          _Kpi(
            'À synchroniser',
            '0',
            Icons.cloud_upload,
          ),
          _Kpi(
            'Notifications',
            '0',
            Icons.notifications_active,
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(
    this.label,
    this.value,
    this.icon,
  );

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 34,
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}
