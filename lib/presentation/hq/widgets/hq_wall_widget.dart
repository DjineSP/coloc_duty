// lib/presentation/hq/widgets/hq_wall_widget.dart
import 'package:flutter/material.dart';

class HqWallWidget extends StatelessWidget {
  const HqWallWidget({super.key});

  // Données fictives (à remplacer plus tard par StreamBuilder)
  final List<Map<String, dynamic>> fakeMessages = const [
    {"senderName": "Kevin", "text": "J’ai fait la vaisselle hier soir", "isMe": false},
    {"senderName": "Moi", "text": "Top merci !", "isMe": true},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final surfaceColor = theme.colorScheme.surfaceVariant.withOpacity(0.3);

    return Card(
      elevation: isDark ? 2 : 4,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          // Zone messages
          Container(
            height: 150,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primary.withOpacity(isDark ? 0.15 : 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: fakeMessages.isEmpty
                ? Center(
              child: Text(
                "Pas encore de messages.\nDis bonjour !",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            )
                : ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fakeMessages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final msg = fakeMessages[i];
                final isMe = msg['isMe'] as bool;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 240),
                    decoration: BoxDecoration(
                      color: isMe
                          ? primary.withOpacity(isDark ? 0.3 : 0.15)
                          : surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: isMe ? null : Border.all(color: theme.dividerColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Text(
                            msg['senderName'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        Text(
                          msg['text'],
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Zone saisie
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Écrire un mot...",
                      hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}