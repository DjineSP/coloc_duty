// lib/presentation/auth/profile_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _pseudoController = TextEditingController();
  String _selectedAvatar = 'assets/avatars/bear.png';
  bool _isLoading = false;

  final List<String> _avatars = [
    'assets/avatars/bear.png',
    'assets/avatars/grizzly.png', // Assure-toi que ce fichier existe
    'assets/avatars/cat.png',
    'assets/avatars/dog.png',
    'assets/avatars/fox.png',
    'assets/avatars/rabbit.png',
    'assets/avatars/panda.png',
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Qui es-tu ?"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      // LayoutBuilder nous donne la hauteur disponible de l'écran
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // ConstrainedBox force le contenu à prendre au moins la hauteur de l'écran
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              // IntrinsicHeight permet d'utiliser Spacer() à l'intérieur d'un ScrollView
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "Choisis ton avatar et ton pseudo pour la colocation.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 40),

                      // --- SÉLECTION AVATAR ---
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _avatars.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final avatarPath = _avatars[index];
                            final isSelected = _selectedAvatar == avatarPath;

                            return GestureDetector(
                              onTap: () => setState(() => _selectedAvatar = avatarPath),
                              child: Container(
                                width: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: isSelected ? Border.all(color: primary, width: 4) : null,
                                  color: Colors.grey[200],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  // --- CORRECTION AFFICHAGE AVATAR ---
                                  // On essaie d'afficher l'image, sinon une lettre en cas d'erreur
                                  child: SizedBox(
                                    width: 60,   // taille de ton cercle
                                    height: 60,
                                    child: ClipOval(
                                      clipBehavior: Clip.antiAlias, // ← IMPORTANT : coupe nette et lisse
                                      child: Image.asset(
                                        avatarPath,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        alignment: Alignment.center,
                                        errorBuilder: (context, error, stackTrace) {
                                          final initial = avatarPath.split('/').last[0].toUpperCase();

                                          return Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            color: Theme.of(context).colorScheme.primary,
                                            alignment: Alignment.center,
                                            child: Text(
                                              initial,
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text("Avatar sélectionné", style: TextStyle(color: primary, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 40),

                      // --- CHAMP PSEUDO ---
                      TextField(
                        controller: _pseudoController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: "Ton Pseudo",
                          hintText: "Surnom, Prénom...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),

                      // Le Spacer va maintenant pousser le bouton vers le bas
                      // mais rétrécira si le clavier s'ouvre sans faire d'overflow
                      const Spacer(),
                      const SizedBox(height: 20),

                      // --- BOUTON VALIDER ---
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _submitProfile(context),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                              : const Text("C'est parti !", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitProfile(BuildContext context) async {
    final pseudo = _pseudoController.text.trim();
    if (pseudo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Choisis un pseudo stp !"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final colocId = await FirestoreService.getCurrentColocId();
    if (colocId != null) {
      final success = await FirestoreService.updateUserProfile(colocId, pseudo, _selectedAvatar);

      if (success && mounted) {
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de connexion..."), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }
}