// lib/presentation/app/tabs/hq_tab.dart
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../presentation/hq/widgets/hq_wall_widget.dart';
import '../../presentation/hq/widgets/hq_actions_section.dart';

class HqTab extends StatefulWidget {
  const HqTab({super.key});

  @override
  State<HqTab> createState() => _HqTabState();
}

class _HqTabState extends State<HqTab> {
  String? _colocId;

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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dans ton hq_tab.dart → remplace ces lignes :

            Text(
              "Mur de la Coloc",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
            const HqWallWidget(),

            const SizedBox(height: 20),

            Text(
              "Administration",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 16),
            const HqActionsSection(),

            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_vote, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Démocratie totale activée",
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}