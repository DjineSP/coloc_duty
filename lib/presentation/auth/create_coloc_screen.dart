// lib/presentation/auth/create_coloc_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';

class CreateColocScreen extends StatefulWidget {
  const CreateColocScreen({super.key});

  @override
  State<CreateColocScreen> createState() => _CreateColocScreenState();
}

class _CreateColocScreenState extends State<CreateColocScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Créer une colocation")),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Nom de ta nouvelle coloc",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: "ex: Le Chateau...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.home),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createColoc,
                child: _isLoading
                    ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                    : const Text("Créer et Continuer", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createColoc() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    // 1. Création avec nom générique pour l'admin
    final colocId = await FirestoreService.createColocation(name);

    if (colocId != null && mounted) {
      // 2. Redirection vers la configuration du profil
      context.go('/auth/setup');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la création"), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }
}