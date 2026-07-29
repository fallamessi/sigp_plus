import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIGP+'),
        actions: [
          const Chip(label: Text('En ligne')),
          IconButton(
            tooltip: 'Synchroniser',
            onPressed: () {},
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const NavigationDrawer(
        children: [
          DrawerHeader(
            child: Text(
              'CNPS — SIGP+',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.dashboard),
            label: Text('Tableau de bord'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.folder),
            label: Text('Dossiers'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.people),
            label: Text('Personnes'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.description),
            label: Text('Documents'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.account_tree),
            label: Text('Workflow'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.archive),
            label: Text('Archives'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              'Tableau de bord',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            const Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _Kpi('Dossiers', '0', Icons.folder),
                _Kpi('En cours', '0', Icons.timelapse),
                _Kpi('Rejetés', '0', Icons.cancel),
                _Kpi('Liquidés', '0', Icons.verified),
                _Kpi('Erreurs sync', '0', Icons.sync_problem),
              ],
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Les graphiques, activités récentes et alertes seront '
                  'alimentés par l’API.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 36),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(label),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
