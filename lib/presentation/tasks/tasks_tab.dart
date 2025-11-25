// lib/presentation/tasks/tasks_tab.dart
import 'package:flutter/material.dart';

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // === TÂCHES DU JOUR ===
              _buildSectionTitle(context, "Aujourd’hui", Icons.today, primary),
              const SizedBox(height: 12),

              // Tâche 1
              TodayTaskItem(
                icon: Icons.local_laundry_service,
                taskName: "Vaisselle",
                initialStatus: TaskStatus.todo,
              ),
              const SizedBox(height: 12),

              // Tâche 2 (déjà marquée comme faite → en attente validation)
              TodayTaskItem(
                icon: Icons.delete_outline,
                taskName: "Sortir les poubelles",
                initialStatus: TaskStatus.pending,
              ),

              const SizedBox(height: 32),

              // === PROCHAINES TÂCHES ===
              _buildSectionTitle(context, "À venir", Icons.calendar_today_outlined, Colors.orange),
              const SizedBox(height: 16),

              _buildUpcomingTask(context, "Demain", "Lun. 25 nov", Icons.cleaning_services, "Nettoyer la salle de bain"),
              const SizedBox(height: 12),
              _buildUpcomingTask(context, "Mercredi", "26 nov", Icons.air, "Passer l’aspirateur"),
              const SizedBox(height: 12),
              _buildUpcomingTask(context, "Vendredi", "28 nov", Icons.shopping_cart_outlined, "Courses communes"),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildUpcomingTask(BuildContext context, String day, String date, IconData icon, String taskName) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Column(children: [
            Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ]),
          const SizedBox(width: 16),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: primary.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: primary, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Text(taskName, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// Widget autonome avec état local → le bouton "Fait" marche !
class TodayTaskItem extends StatefulWidget {
  final IconData icon;
  final String taskName;
  final TaskStatus initialStatus;

  const TodayTaskItem({
    super.key,
    required this.icon,
    required this.taskName,
    required this.initialStatus,
  });

  @override
  State<TodayTaskItem> createState() => _TodayTaskItemState();
}

class _TodayTaskItemState extends State<TodayTaskItem> {
  late TaskStatus status;

  @override
  void initState() {
    super.initState();
    status = widget.initialStatus;
  }

  void _markAsDone() {
    setState(() {
      status = TaskStatus.pending;
    });
    // Ici tu pourras appeler Firestore plus tard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tâche marquée comme faite ! En attente de validation..."), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: status == TaskStatus.done ? Colors.green.withOpacity(0.1) : theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status == TaskStatus.pending ? Colors.orange.withOpacity(0.6) : (status == TaskStatus.done ? Colors.green : Colors.transparent),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: status == TaskStatus.done
                  ? Colors.green
                  : (status == TaskStatus.pending ? Colors.orange : primary),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.taskName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    decoration: status == TaskStatus.done ? TextDecoration.lineThrough : null,
                    color: status == TaskStatus.done ? Colors.grey[600] : null,
                  ),
                ),
                if (status == TaskStatus.pending)
                  Text("En attente de validation", style: TextStyle(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (status == TaskStatus.todo)
            ElevatedButton(
              onPressed: _markAsDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text("Fait", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            )
          else if (status == TaskStatus.done)
            const Icon(Icons.check_circle, color: Colors.green, size: 32)
          else if (status == TaskStatus.pending)
              const Icon(Icons.schedule, color: Colors.orange, size: 28),
        ],
      ),
    );
  }
}

enum TaskStatus { todo, pending, done }