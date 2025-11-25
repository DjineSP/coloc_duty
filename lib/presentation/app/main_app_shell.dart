// lib/presentation/app/main_app_shell.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../tasks/tasks_tab.dart';
import '../calendar/calendar_tab.dart';
import '../hq/hq_tab.dart';
import './coloc_drawer.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 0;
  String? _colocId;

  final List<Widget> _tabs = const [
    TasksTab(),
    CalendarTab(),
    HqTab(),
  ];

  final List<String> _titles = const [
    "Tâches",
    "Calendrier",
    "QG",
  ];

  @override
  void initState() {
    super.initState();
    _loadColocData();
  }

  Future<void> _loadColocData() async {
    final id = await FirestoreService.getCurrentColocId();
    if (mounted) setState(() => _colocId = id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary; // CORRIGÉ : == → =

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          // ICÔNE NOTIFICATIONS + BADGE
          if (_colocId != null) _NotificationBellWithBadge(colocId: _colocId!),

          // AVATAR
          if (_colocId != null) _CurrentMemberAvatar(colocId: _colocId!),

          const SizedBox(width: 12),
        ],
      ),

      drawer: const ColocDrawer(),

      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
          selectedItemColor: primary,
          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: "Tâches"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: "Calendrier"),
            BottomNavigationBarItem(icon: Icon(Icons.home_work_outlined), activeIcon: Icon(Icons.home_work), label: "QG"),
          ],
        ),
      ),
    );
  }
}

// ICÔNE NOTIFICATIONS AVEC BADGE DYNAMIQUE
class _NotificationBellWithBadge extends StatelessWidget {
  final String colocId;
  const _NotificationBellWithBadge({required this.colocId});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('colocations')
          .doc(colocId)
          .collection('tasks')
          .where('validated', isEqualTo: false)
          .where('completedBy', isEqualTo: myUid)
          .snapshots(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?.docs.length ?? 0;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 28),
                onPressed: () {
                  if (pendingCount > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$pendingCount tâche${pendingCount > 1 ? 's' : ''} en attente de validation")),
                    );
                  }
                },
              ),
              if (pendingCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      pendingCount > 99 ? "99+" : "$pendingCount",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// AVATAR UTILISATEUR
class _CurrentMemberAvatar extends StatelessWidget {
  final String colocId;
  const _CurrentMemberAvatar({required this.colocId});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('colocations').doc(colocId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final members = snapshot.data?.get('members') as List<dynamic>? ?? [];
        final me = members.cast<Map<String, dynamic>>().firstWhere(
              (m) => m['uid'] == myUid,
          orElse: () => <String, dynamic>{},
        );

        if (me.isEmpty) return const SizedBox();

        final displayName = me['displayName'] ?? "M";
        final photoUrl = me['photoUrl'] as String?;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: photoUrl != null && photoUrl.startsWith('assets/')
                ? ClipOval(child: Image.asset(photoUrl, fit: BoxFit.cover))
                : Text(
              displayName[0].toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}