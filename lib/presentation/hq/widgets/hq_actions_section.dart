// lib/presentation/hq/widgets/hq_actions_section.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HqActionsSection extends StatelessWidget {
  const HqActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      elevation: theme.brightness == Brightness.dark ? 2 : 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          _tile(
            context,
            icon: Icons.cleaning_services_outlined,
            title: "Gérer les tâches",
            onTap: () => context.push('/hq/tasks'),
            isFirst: true,
          ),
          _tile(
            context,
            icon: Icons.sync,
            title: "Tourniquet",
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Attribution en cours...")),
            ),
          ),
          _tile(
            context,
            icon: Icons.bar_chart,
            title: "Statistiques",
            onTap: () => context.push('/hq/stats'),
          ),
          _tile(
            context,
            icon: Icons.history,
            title: "Historique",
            onTap: () => context.push('/hq/history'),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _tile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        bool isFirst = false,
        bool isLast = false,
      }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 24),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15.5,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(18) : Radius.zero,
              bottom: isLast ? const Radius.circular(18) : Radius.zero,
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 0.5, color: theme.dividerColor.withOpacity(0.3), indent: 72),
      ],
    );
  }
}