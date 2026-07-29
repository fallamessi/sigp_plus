import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('SIGP+ — Tableau de bord')),
      body: Row(children: [
        NavigationRail(
            extended: true,
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.dashboard), label: Text('Tableau de bord')),
              NavigationRailDestination(
                  icon: Icon(Icons.folder), label: Text('Dossiers')),
              NavigationRailDestination(
                  icon: Icon(Icons.people), label: Text('Personnes')),
              NavigationRailDestination(
                  icon: Icon(Icons.description), label: Text('Documents')),
              NavigationRailDestination(
                  icon: Icon(Icons.settings), label: Text('Administration'))
            ],
            selectedIndex: 0),
        const VerticalDivider(width: 1),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: GridView.count(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: const [
                      _Card('Dossiers', '0', Icons.folder),
                      _Card('En cours', '0', Icons.pending_actions),
                      _Card('Rejetés', '0', Icons.cancel),
                      _Card('Liquidés', '0', Icons.verified)
                    ])))
      ]));
}

class _Card extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _Card(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext c) => Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 34),
            const Spacer(),
            Text(value, style: Theme.of(c).textTheme.headlineLarge),
            Text(label)
          ])));
}
