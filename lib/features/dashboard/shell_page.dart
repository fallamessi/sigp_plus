import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../shared/crud_page.dart';

class ShellPage extends ConsumerStatefulWidget {
  const ShellPage({super.key});
  @override
  ConsumerState<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends ConsumerState<ShellPage> {
  int index = 0;
  final pages = const [
    DashboardHome(),
    CrudPage(title: 'Agences', endpoint: '/agences', fields: ['code', 'nom']),
    CrudPage(title: 'Services', endpoint: '/services', fields: ['code', 'nom']),
    CrudPage(
        title: 'Personnes',
        endpoint: '/personnes',
        fields: ['matricule', 'titre', 'nom', 'prenom', 'telephone', 'email']),
    CrudPage(
        title: 'Dossiers',
        endpoint: '/dossiers',
        fields: ['numero_dossier', 'ref_ged', 'statut_courant'])
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text([
            'Tableau de bord',
            'Agences',
            'Services',
            'Personnes',
            'Dossiers'
          ][index]),
          actions: [
            IconButton(
                onPressed: () async {
                  await ref.read(authServiceProvider).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout))
          ]),
      body: Row(children: [
        NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (v) => setState(() => index = v),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(
                  icon: Icon(Icons.business), label: Text('Agences')),
              NavigationRailDestination(
                  icon: Icon(Icons.account_tree), label: Text('Services')),
              NavigationRailDestination(
                  icon: Icon(Icons.people), label: Text('Personnes')),
              NavigationRailDestination(
                  icon: Icon(Icons.folder), label: Text('Dossiers'))
            ]),
        const VerticalDivider(width: 1),
        Expanded(child: pages[index])
      ]));
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: const [
            _Card('Dossiers', '0', Icons.folder),
            _Card('En cours', '0', Icons.hourglass_top),
            _Card('Liquidés', '0', Icons.verified),
            _Card('Rejetés', '0', Icons.block)
          ]));
}

class _Card extends StatelessWidget {
  const _Card(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Icon(icon, size: 38),
            const SizedBox(width: 16),
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  Text(label)
                ])
          ])));
}
