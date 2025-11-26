import 'package:flutter/material.dart';

class HqHistoryScreen extends StatelessWidget {
  const HqHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Données fictives
    final history = [
      {"action": "Vaisselle", "user": "Kevin", "date": "Aujourd'hui, 10:30"},
      {"action": "Poubelles", "user": "Moi", "date": "Hier, 19:45"},
      {"action": "Nettoyage SdB", "user": "Sarah", "date": "Hier, 09:00"},
      {"action": "Courses", "user": "Kevin", "date": "Lun. 24 Nov"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Historique")),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.surfaceVariant,
              child: const Icon(Icons.check, size: 16),
            ),
            title: Text(
              item['action']!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text("${item['user']} • ${item['date']}"),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          );
        },
      ),
    );
  }
}