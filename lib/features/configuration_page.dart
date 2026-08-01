import 'package:flutter/material.dart';

import 'crud_page.dart';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  static const _tabs = [
    Tab(text: 'Agences', icon: Icon(Icons.business_outlined)),
    Tab(text: 'Motifs de rejet', icon: Icon(Icons.block_outlined)),
    Tab(text: 'Rôles', icon: Icon(Icons.badge_outlined)),
    Tab(text: 'Permissions', icon: Icon(Icons.admin_panel_settings_outlined)),
    Tab(text: 'Services', icon: Icon(Icons.account_tree_outlined)),
    Tab(text: 'Types de dossier', icon: Icon(Icons.folder_copy_outlined)),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _controller,
            isScrollable: true,
            tabs: _tabs,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: const [
              CrudPage(
                title: 'Agences',
                entity: 'agences',
                fields: {
                  'code': 'Code',
                  'nom': 'Nom',
                  'adresse': 'Adresse',
                  'telephone': 'Téléphone',
                  'email': 'E-mail',
                  'actif': 'Actif',
                },
                booleanFields: {'actif'},
              ),
              CrudPage(
                title: 'Catégories de motif de rejet',
                entity: 'categories_motif_rejet',
                fields: {
                  'code': 'Code',
                  'libelle': 'Libellé',
                  'description': 'Description',
                  'actif': 'Actif',
                },
                booleanFields: {'actif'},
              ),
              CrudPage(
                title: 'Rôles',
                entity: 'roles',
                fields: {
                  'code': 'Code',
                  'nom': 'Nom',
                  'description': 'Description',
                  'actif': 'Actif',
                },
                booleanFields: {'actif'},
              ),
              CrudPage(
                title: 'Permissions des rôles',
                entity: 'role_permissions',
                fields: {
                  'role_id': 'Rôle',
                  'permission': 'Permission',
                  'autorise': 'Autorisé',
                },
                relations: {
                  'role_id': RelationConfig(
                    table: 'roles',
                    labelFields: ['nom', 'code'],
                  ),
                },
                booleanFields: {'autorise'},
              ),
              CrudPage(
                title: 'Services',
                entity: 'services',
                fields: {
                  'code': 'Code',
                  'nom': 'Nom',
                  'description': 'Description',
                  'agence_id': 'Agence',
                  'actif': 'Actif',
                },
                relations: {
                  'agence_id': RelationConfig(
                    table: 'agences',
                    labelFields: ['nom', 'code'],
                  ),
                },
                booleanFields: {'actif'},
              ),
              CrudPage(
                title: 'Types de dossier',
                entity: 'types_dossier',
                fields: {
                  'code': 'Code',
                  'libelle': 'Libellé',
                  'description': 'Description',
                  'delai_traitement_jours': 'Délai de traitement (jours)',
                  'actif': 'Actif',
                },
                booleanFields: {'actif'},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
