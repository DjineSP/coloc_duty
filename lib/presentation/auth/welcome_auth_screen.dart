// lib/presentation/auth/welcome_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeAuthScreen extends StatelessWidget {
  const WelcomeAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // === PARTIE HAUT : Contenu flexible (logo + texte) ===
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40), // Espace en haut

                    // Logo
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcATop),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Titre stylé
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        children: [
                          const TextSpan(text: "Bienvenue dans ta\n"),
                          TextSpan(
                            text: "Coloc Duty",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 38,
                            ),
                          ),
                          const TextSpan(text: " !"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Crée une nouvelle colocation ou rejoins-en une avec un code d’invitation.",
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // === PARTIE BAS : Boutons toujours visibles ===
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
              child: Column(
                children: [
                  // Bouton Créer une colocation
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/auth/create'),
                      icon: const Icon(Icons.add_home_work_outlined, size: 28),
                      label: const Text(
                        "Créer une colocation",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bouton Rejoindre
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/auth/join'),
                      icon: const Icon(Icons.login, size: 28),
                      label: const Text(
                        "Rejoindre avec un code",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: primaryColor, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}