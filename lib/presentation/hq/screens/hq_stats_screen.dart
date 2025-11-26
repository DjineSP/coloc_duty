import 'package:flutter/material.dart';

class HqStatsScreen extends StatelessWidget {
  const HqStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Données fictives pour l'instant
    final stats = [
      {"name": "Kevin", "count": 12, "color": Colors.blue},
      {"name": "Sarah", "count": 8, "color": Colors.purple},
      {"name": "Moi", "count": 5, "color": theme.colorScheme.primary},
      {"name": "Thomas", "count": 0, "color": Colors.orange},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Classement")),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 15),
        itemBuilder: (context, index) {
          final user = stats[index];
          final isFirst = index == 0;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: isFirst ? Border.all(color: Colors.amber, width: 2) : null,
              boxShadow: [
                if (isFirst)
                  BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)
              ],
            ),
            child: Row(
              children: [
                // Rang
                Container(
                  width: 30,
                  alignment: Alignment.center,
                  child: Text(
                    "#${index + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isFirst ? Colors.amber : theme.disabledColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Avatar
                CircleAvatar(
                  backgroundColor: (user['color'] as Color).withOpacity(0.2),
                  child: Text((user['name'] as String)[0]),
                ),
                const SizedBox(width: 16),

                // Nom & Barre de progression
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (user['count'] as int) / 20, // Échelle arbitraire
                          backgroundColor: theme.dividerColor.withOpacity(0.1),
                          color: user['color'] as Color,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),

                // Score
                const SizedBox(width: 12),
                Text(
                  "${user['count']}",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}