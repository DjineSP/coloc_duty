// lib/presentation/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'onboarding_data.dart';
import '../../data/local/preferences_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Fonction pour passer directement à la fin
  Future<void> _skipOnboarding() async {
    await PreferencesService.completeOnboarding();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // === PAGEVIEW ===
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: onboardingPages.length,
              itemBuilder: (context, index) {
                final page = onboardingPages[index];

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(40, 40, 40, 120),
                        child: Column(
                          children: [
                            const Spacer(flex: 2),

                            Image.asset(
                              page.imagePath,
                              height: 240,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 60),

                            Text(
                              page.title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            Text(
                              page.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),

                            const Spacer(flex: 3),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // === BOUTON "PASSER" EN HAUT À DROITE ===
            Positioned(
              top: 20,
              right: 20,
              child: TextButton.icon(
                onPressed: _skipOnboarding,
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: const Text("Passer"),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            // === INDICATEUR DE PAGE ===
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: onboardingPages.length,
                  effect: WormEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    spacing: 16,
                    activeDotColor: Theme.of(context).colorScheme.primary,
                    dotColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
            ),

            // === BOUTON SUIVANT / COMMENCER ===
            Positioned(
              left: 40,
              right: 40,
              bottom: 30,
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_currentPage == onboardingPages.length - 1) {
                      await PreferencesService.completeOnboarding();
                      if (mounted) context.go('/auth');
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _currentPage == onboardingPages.length - 1 ? "Commencer !" : "Suivant",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}