// lib/presentation/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppStatus();
  }

  Future<void> _checkAppStatus() async {
    // Petit délai pour l'UX (laisser le temps de voir le logo)
    await Future.delayed(const Duration(milliseconds: 2000));

    // Vérification cohérente : Est-ce que j'ai un ID local ET est-ce que je suis toujours membre ?
    final isValidMember = await FirestoreService.verifyUserColocAccess();

    if (!mounted) return;

    if (isValidMember) {
      context.go('/home');
    } else {
      // Si pas membre ou ID invalide, on redirige vers l'auth
      // On pourrait vérifier onboardingCompleted ici si besoin
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcATop),
                child: Image.asset('assets/images/logo.png', width: 160, height: 160, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Coloc Duty",
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            SpinKitSpinningLines(color: Colors.white, size: 60.0),
          ],
        ),
      ),
    );
  }
}