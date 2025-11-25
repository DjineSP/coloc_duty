// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/splash/splash_screen.dart';
import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/auth/welcome_auth_screen.dart';
import '../presentation/auth/create_coloc_screen.dart';
import '../presentation/auth/join_coloc_screen.dart';
import '../presentation/auth/profile_setup_screen.dart';
import '../presentation/app/main_app_shell.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),

    // Nouvelles routes authentification
    GoRoute(path: '/auth', builder: (context, state) => const WelcomeAuthScreen()),
    GoRoute(path: '/auth/create', builder: (context, state) => const CreateColocScreen()),
    GoRoute(path: '/auth/join', builder: (context, state) => const JoinColocScreen()),
    GoRoute(path: '/auth/setup', builder: (context, state) => const ProfileSetupScreen()),

    GoRoute(
      path: '/home',
      builder: (context, state) => const MainAppShell(),
    ),
  ],
);