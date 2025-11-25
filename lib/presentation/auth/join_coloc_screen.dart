// lib/presentation/auth/join_coloc_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';

class JoinColocScreen extends StatefulWidget {
  const JoinColocScreen({super.key});

  @override
  State<JoinColocScreen> createState() => _JoinColocScreenState();
}

class _JoinColocScreenState extends State<JoinColocScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isValid = _codeController.text.trim().length == 6;

    return Scaffold(
      appBar: AppBar(title: const Text("Rejoindre")),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Text("Entre le code d'invitation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: TextStyle(fontSize: 32, letterSpacing: 8, color: primary, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: "",
                hintText: "######",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (isValid && !_isLoading) ? _joinColoc : null,
                child: _isLoading
                    ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                    : const Text("Rejoindre", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinColoc() async {
    setState(() => _isLoading = true);

    // 1. On rejoint (Firestore assigne un nom par défaut type "Colocataire X")
    final colocId = await FirestoreService.joinColocation(_codeController.text);

    if (colocId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Code valide ! configure ton profil.")),
      );
      // 2. On va vers le setup profil
      context.go('/auth/setup');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Code invalide ou erreur réseau"), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }
}