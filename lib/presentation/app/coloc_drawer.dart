// lib/presentation/app/coloc_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/local/preferences_service.dart';
import '../../services/firestore_service.dart';

class ColocDrawer extends StatefulWidget {
  const ColocDrawer({super.key});

  @override
  State<ColocDrawer> createState() => _ColocDrawerState();
}

class _ColocDrawerState extends State<ColocDrawer> {
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
    final primary = theme.colorScheme.primary;

    if (_colocId == null) {
      return const Drawer(child: Center(child: CircularProgressIndicator()));
    }

    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('colocations').doc(_colocId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return const Center(child: Text("Colocation introuvable"));

          final name = data['name'] ?? "Ma Coloc";
          final code = data['inviteCode'] ?? "---";
          final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
          final currentUid = FirebaseAuth.instance.currentUser?.uid;

          return Column(
            children: [
              // HEADER PERSONNALISÉ – Hauteur contrôlée à 100%
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, primary.withOpacity(0.8)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text("Code : ", style: TextStyle(fontSize: 16, color: Colors.white70)),
                        SelectableText(
                          code,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Code copié !"), duration: Duration(seconds: 1)),
                            );
                          },
                          child: const Icon(Icons.copy, size: 22, color: Colors.white70),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      "${members.length} membre${members.length > 1 ? 's' : ''}",
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // ACTIONS
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text("Inviter un colocataire"),
                onTap: () {
                  Navigator.pop(context);
                  Share.share("Rejoins « $name » sur Coloc Duty avec le code : $code");
                },
              ),
              const Divider(height: 1),

              // LISTE DES MEMBRES
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: members.length,
                  itemBuilder: (context, i) {
                    final m = members[i];
                    final isMe = m['uid'] == currentUid;
                    final displayName = m['displayName'] ?? "Inconnu";
                    final photoUrl = m['photoUrl'] as String?;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: photoUrl != null && photoUrl.startsWith('assets/')
                            ? ClipOval(child: Image.asset(photoUrl, fit: BoxFit.cover))
                            : Text(
                          displayName[0].toUpperCase(),
                          style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(displayName, style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                      trailing: isMe ? const Chip(label: Text("Moi", style: TextStyle(fontSize: 10)), backgroundColor: Colors.transparent) : null,
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // QUITTER
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Quitter la colocation", style: TextStyle(color: Colors.red)),
                onTap: () => _showLeaveDialog(context),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Quitter la colocation ?"),
        content: const Text("Tu devras entrer le code pour revenir."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);

              await FirebaseAuth.instance.signOut();
              await PreferencesService.saveCurrentColocId("");

              if (context.mounted) context.go('/auth');
            },
            child: const Text("Quitter", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}