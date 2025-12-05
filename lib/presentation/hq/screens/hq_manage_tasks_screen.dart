import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/firestore_service.dart';
import '../../../services/task_firestore_service.dart';

class HqManageTasksScreen extends StatefulWidget {
  const HqManageTasksScreen({super.key});

  @override
  State<HqManageTasksScreen> createState() => _HqManageTasksScreenState();
}

class _HqManageTasksScreenState extends State<HqManageTasksScreen> {
  String? _colocId;

  // Petite liste d'icônes possibles pour les tâches
  final Map<String, IconData> _iconChoices = const {
    'cleaning': Icons.cleaning_services,
    'trash': Icons.delete_outline,
    'dishes': Icons.local_laundry_service,
    'shopping': Icons.shopping_cart_outlined,
    'bathroom': Icons.bathtub_outlined,
    'cooking': Icons.restaurant_menu,
    'laundry': Icons.local_laundry_service,
    'plants': Icons.grass,
    'pet': Icons.pets,
    'bills': Icons.receipt_long,
    'other': Icons.task_alt,
  };

  String _recurrenceLabel(String value) {
    switch (value) {
      case 'quotidien':
        return 'Quotidien';
      case 'hebdo':
        return 'Hebdomadaire';
      case 'mensuel':
        return 'Mensuel';
      case 'ponctuel':
        return 'Ponctuel';
    }

    // Gestion des intervalles personnalisés: interval_N => "Tous les N jours"
    if (value.startsWith('interval_')) {
      final parts = value.split('_');
      if (parts.length == 2) {
        final n = int.tryParse(parts[1]) ?? 0;
        if (n > 0) {
          return 'Tous les $n jour${n > 1 ? 's' : ''}';
        }
      }
    }

    return value.isEmpty ? 'Autre' : value;
  }

  @override
  void initState() {
    super.initState();
    _loadColocId();
  }

  Future<void> _loadColocId() async {
    final id = await FirestoreService.getCurrentColocId();
    if (mounted) setState(() => _colocId = id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_colocId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tasksRef = FirebaseFirestore.instance
        .collection('colocations')
        .doc(_colocId)
        .collection('taskDefinitions')
        .orderBy('title');

    return Scaffold(
      appBar: AppBar(title: const Text("Gérer les tâches")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskDialog,
        label: const Text("Nouvelle tâche"),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: tasksRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("Aucune tâche définie pour l'instant."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = (data['title'] as String?) ?? 'Tâche sans nom';
              final recurrence = (data['recurrence'] as String?) ?? '---';
              final modifiedAt = data['modifiedAt'];
              final iconKey = (data['iconKey'] as String?) ?? 'other';

              String? modifiedLabel;
              if (modifiedAt is Timestamp) {
                final dt = modifiedAt.toDate();
                modifiedLabel = "Modifié le ${dt.day}/${dt.month}/${dt.year}";
              }

              return InkWell(
                onTap: () => _showEditTaskDialog(doc.id, data),
                borderRadius: BorderRadius.circular(16),
                child: Card(
                  elevation: 0,
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.dividerColor.withOpacity(0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _iconChoices[iconKey] ?? Icons.task_alt,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _recurrenceLabel(recurrence),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (modifiedLabel != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      modifiedLabel,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, size: 20, color: theme.iconTheme.color?.withOpacity(0.6)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateTaskDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    // Valeur de contrôle pour le dropdown (inclut un mode "interval")
    String recurrenceControl = 'hebdo';
    int intervalDays = 3;
    String selectedIconKey = 'other';
    final intervalController = TextEditingController(text: intervalDays.toString());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Nouvelle tâche",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: recurrenceControl,
                      items: const [
                        DropdownMenuItem(value: 'quotidien', child: Text('Quotidien')),
                        DropdownMenuItem(value: 'hebdo', child: Text('Hebdomadaire')),
                        DropdownMenuItem(value: 'mensuel', child: Text('Mensuel')),
                        DropdownMenuItem(value: 'ponctuel', child: Text('Ponctuel')),
                        DropdownMenuItem(value: 'interval', child: Text('Tous les X jours')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() => recurrenceControl = v);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Récurrence', border: OutlineInputBorder()),
                    ),
                    if (recurrenceControl == 'interval') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Tous les'),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 70,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                              controller: intervalController,
                              onChanged: (value) {
                                final parsed = int.tryParse(value);
                                if (parsed != null && parsed > 0) {
                                  setModalState(() => intervalDays = parsed);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('jours'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text("Icône", style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _iconChoices.entries.map((entry) {
                          final isSelected = selectedIconKey == entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Icon(entry.value, size: 20),
                              selected: isSelected,
                              onSelected: (_) {
                                setModalState(() => selectedIconKey = entry.key);
                              },
                              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          final effectiveRecurrence = recurrenceControl == 'interval'
                              ? 'interval_${intervalDays.clamp(1, 365)}'
                              : recurrenceControl;

                          await TaskFirestoreService.createTaskDefinition(
                            title: title,
                            description: descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            recurrence: effectiveRecurrence,
                            iconKey: selectedIconKey,
                          );

                          if (mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showEditTaskDialog(String taskId, Map<String, dynamic> data) async {
    final titleController = TextEditingController(text: data['title'] as String? ?? '');
    final descriptionController = TextEditingController(text: data['description'] as String? ?? '');

    final storedRecurrence = (data['recurrence'] as String?) ?? 'hebdo';
    String recurrenceControl = storedRecurrence;
    int intervalDays = 3;

    if (storedRecurrence.startsWith('interval_')) {
      final parts = storedRecurrence.split('_');
      if (parts.length == 2) {
        final n = int.tryParse(parts[1]) ?? 3;
        if (n > 0) intervalDays = n;
      }
      recurrenceControl = 'interval';
    }
    String selectedIconKey = (data['iconKey'] as String?) ?? 'other';
    final intervalController = TextEditingController(text: intervalDays.toString());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Détails de la tâche",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: recurrenceControl,
                      items: const [
                        DropdownMenuItem(value: 'quotidien', child: Text('Quotidien')),
                        DropdownMenuItem(value: 'hebdo', child: Text('Hebdomadaire')),
                        DropdownMenuItem(value: 'mensuel', child: Text('Mensuel')),
                        DropdownMenuItem(value: 'ponctuel', child: Text('Ponctuel')),
                        DropdownMenuItem(value: 'interval', child: Text('Tous les X jours')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() => recurrenceControl = v);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Récurrence', border: OutlineInputBorder()),
                    ),
                    if (recurrenceControl == 'interval') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Tous les'),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 70,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                              controller: intervalController,
                              onChanged: (value) {
                                final parsed = int.tryParse(value);
                                if (parsed != null && parsed > 0) {
                                  setModalState(() => intervalDays = parsed);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('jours'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text("Icône", style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _iconChoices.entries.map((entry) {
                          final isSelected = selectedIconKey == entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Icon(entry.value, size: 20),
                              selected: isSelected,
                              onSelected: (_) {
                                setModalState(() => selectedIconKey = entry.key);
                              },
                              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: ctx,
                              builder: (dialogCtx) {
                                return AlertDialog(
                                  title: const Text('Supprimer la tâche ?'),
                                  content: const Text('Cette action est irréversible.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmed == true) {
                              await TaskFirestoreService.deleteTaskDefinition(taskId);
                              if (mounted) Navigator.pop(ctx);
                            }
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Supprimer'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            final title = titleController.text.trim();
                            if (title.isEmpty) return;

                            final effectiveRecurrence = recurrenceControl == 'interval'
                                ? 'interval_${intervalDays.clamp(1, 365)}'
                                : recurrenceControl;

                            await TaskFirestoreService.updateTaskDefinition(
                              taskId,
                              title: title,
                              description: descriptionController.text.trim(),
                              recurrence: effectiveRecurrence,
                              iconKey: selectedIconKey,
                            );

                            if (mounted) Navigator.pop(ctx);
                          },
                          child: const Text('Enregistrer'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}