import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/local/preferences_service.dart';

class HqTourniquetScreen extends StatefulWidget {
  const HqTourniquetScreen({super.key});

  @override
  State<HqTourniquetScreen> createState() => _HqTourniquetScreenState();
}

class _HqTourniquetScreenState extends State<HqTourniquetScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _members = [];
  
  // Configuration simple pour chaque tâche
  Map<String, bool> _isIndividualTask = {}; // taskId -> est une tâche fixe
  Map<String, String?> _fixedAssignments = {}; // taskId -> memberId (tâches fixes)
  Map<String, List<String>> _rotationOrder = {}; // taskId -> ordre des membres pour tourniquet

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final colocId = await PreferencesService.getCurrentColocId();
      if (colocId == null) return;

      // Charger les tâches
      final tasksSnap = await FirebaseFirestore.instance
          .collection('colocations')
          .doc(colocId)
          .collection('taskDefinitions')
          .get();
      _tasks = tasksSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      // Charger les membres
      final membersSnap = await FirebaseFirestore.instance
          .collection('colocations')
          .doc(colocId)
          .collection('members')
          .get();
      _members = membersSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      // Initialiser la configuration par défaut
      _initializeDefaultConfig();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur chargement : $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initializeDefaultConfig() {
    for (final task in _tasks) {
      final taskId = task['id'] as String;
      // Par défaut : tourniquet avec tous les membres dans l'ordre
      _isIndividualTask[taskId] = false;
      _rotationOrder[taskId] = _members.map((m) => m['uid'] as String).toList();
    }
  }

  void _showTaskConfigDialog(String taskId) {
    final task = _tasks.firstWhere((t) => t['id'] == taskId);
    final isIndividual = _isIndividualTask[taskId] ?? false;
    final fixedMemberId = _fixedAssignments[taskId];
    final rotationMembers = List<String>.from(_rotationOrder[taskId] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Configurer : ${task['title']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type de tâche
                SwitchListTile(
                  title: const Text('Tâche individuelle (fixe)'),
                  subtitle: const Text('Assignée à une seule personne en permanence'),
                  value: isIndividual,
                  onChanged: (value) {
                    setDialogState(() => _isIndividualTask[taskId] = value);
                  },
                ),
                const Divider(),
                if (isIndividual) ...[
                  const Text('Assigner à :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._members.map((member) => RadioListTile<String>(
                    title: Text(member['nickname'] ?? member['displayName'] ?? 'Inconnu'),
                    value: member['uid'] as String,
                    groupValue: fixedMemberId,
                    onChanged: (value) {
                      setDialogState(() => _fixedAssignments[taskId] = value);
                    },
                  )),
                ] else ...[
                  const Text('Ordre de passage pour le tourniquet :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Glissez-déposez pour réorganiser l\'ordre'),
                  const SizedBox(height: 12),
                  // Liste réorganisable
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rotationMembers.length,
                    onReorder: (oldIndex, newIndex) {
                      setDialogState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = rotationMembers.removeAt(oldIndex);
                        rotationMembers.insert(newIndex, item);
                        _rotationOrder[taskId] = rotationMembers;
                      });
                    },
                    itemBuilder: (context, index) {
                      final memberId = rotationMembers[index];
                      final member = _members.firstWhere((m) => m['uid'] == memberId);
                      return Card(
                        key: ValueKey(memberId),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(member['nickname'] ?? member['displayName'] ?? 'Inconnu'),
                          trailing: const Icon(Icons.drag_handle),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isIndividualTask[taskId] = isIndividual;
                  if (isIndividual && fixedMemberId != null) {
                    _fixedAssignments[taskId] = fixedMemberId;
                  } else {
                    _fixedAssignments.remove(taskId);
                    _rotationOrder[taskId] = rotationMembers;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuration du tourniquet"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildConfigScreen(theme),
    );
  }

  Widget _buildConfigScreen(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Configuration des tâches",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Définissez si chaque tâche est individuelle (fixe) ou en tourniquet, et l'ordre de passage.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = _tasks[index];
              final taskId = task['id'] as String;
              final isIndividual = _isIndividualTask[taskId] ?? false;
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isIndividual ? Colors.red : theme.colorScheme.primary,
                    child: Icon(
                      isIndividual ? Icons.person : Icons.sync,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(task['title'] ?? 'Tâche'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isIndividual ? "Tâche individuelle" : "Tourniquet"),
                      if (isIndividual && _fixedAssignments[taskId] != null)
                        Text("Assigné à : ${_getMemberName(_fixedAssignments[taskId])}"),
                      if (!isIndividual)
                        Text("Ordre : ${_getRotationOrderSummary(taskId)}"),
                    ],
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showTaskConfigDialog(taskId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getMemberName(String? memberId) {
    if (memberId == null) return 'Non assigné';
    final member = _members.firstWhere(
      (m) => m['uid'] == memberId,
      orElse: () => {'nickname': 'Inconnu'},
    );
    return member['nickname'] ?? member['displayName'] ?? 'Inconnu';
  }

  String _getRotationOrderSummary(String taskId) {
    final order = _rotationOrder[taskId] ?? [];
    if (order.isEmpty) return 'Aucun membre';
    
    final names = order.take(3).map((id) => _getMemberName(id)).toList();
    if (order.length > 3) {
      names.add('...');
    }
    return names.join(' → ');
  }
}
