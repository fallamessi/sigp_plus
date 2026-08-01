import 'package:flutter/material.dart';

class ModulePlaceholder extends StatelessWidget {
  const ModulePlaceholder({required this.title, required this.icon, super.key});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Module prêt à recevoir sa logique métier et son API.'),
          ],
        ),
      );
}
