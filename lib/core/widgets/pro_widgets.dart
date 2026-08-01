import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({required this.title, required this.subtitle, this.actions = const [], super.key});
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.navy)),
                const SizedBox(height: 5),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          ...actions.expand((e) => [const SizedBox(width: 10), e]),
        ],
      );
}

class MetricCard extends StatelessWidget {
  const MetricCard({required this.label, required this.value, required this.icon, required this.note, this.alert = false, super.key});
  final String label;
  final String value;
  final IconData icon;
  final String note;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final color = alert ? Colors.red : Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    Text(note, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.value, {super.key});
  final String value;

  @override
  Widget build(BuildContext context) {
    final upper = value.toUpperCase();
    final MaterialColor color = upper.contains('REJET') || upper.contains('ERREUR') || upper.contains('ECHEC')
        ? Colors.red
        : upper.contains('VALID') || upper.contains('ACTIF') || upper.contains('TERMINE') || upper.contains('LIQUIDE')
            ? Colors.green
            : upper.contains('ATTENTE') || upper.contains('VERIFIER') || upper.contains('URGENTE')
                ? Colors.orange
                : upper.contains('ARCHIVE')
                    ? Colors.blueGrey
                    : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(30)),
      child: Text(value.replaceAll('_', ' '), style: TextStyle(color: color.shade700, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class SearchToolbar extends StatelessWidget {
  const SearchToolbar({required this.controller, required this.onChanged, this.extra = const [], super.key});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(child: TextField(controller: controller, onChanged: onChanged, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Rechercher...'))),
              ...extra.expand((e) => [const SizedBox(width: 12), e]),
            ],
          ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(42),
        child: Center(child: Column(children: [const Icon(Icons.search_off, size: 48, color: Colors.grey), const SizedBox(height: 10), Text(label)])),
      );
}
