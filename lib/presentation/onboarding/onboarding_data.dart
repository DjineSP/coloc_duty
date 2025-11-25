// lib/presentation/onboarding/onboarding_data.dart
class OnboardingPage {
  final String imagePath;  // ← maintenant un chemin
  final String title;
  final String description;

  const OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

final List<OnboardingPage> onboardingPages = [
  const OnboardingPage(
    imagePath: "assets/images/onboarding_1.png",
    title: "Fini les disputes de coloc !",
    description: "Coloc Duty répartit équitablement les tâches ménagères sans favoritisme.",
  ),
  const OnboardingPage(
    imagePath: "assets/images/onboarding_2.png",
    title: "Roulement 100% équitable",
    description: "Algorithme round-robin strict : chacun fait chaque tâche le même nombre de fois.",
  ),
  const OnboardingPage(
    imagePath: "assets/images/onboarding_3.png",
    title: "Validation collaborative",
    description: "Tu marques « fait » → les autres confirment ou refusent. Tout est transparent !",
  ),
  const OnboardingPage(
    imagePath: "assets/images/onboarding_4.png",
    title: "Prêt à vivre en paix ?",
    description: "Crée ou rejoins ta colocation en 30 secondes et retrouve l’harmonie.",
  ),
];