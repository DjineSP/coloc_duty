// lib/presentation/calendar/calendar_tab.dart
import 'package:flutter/material.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  // Données fictives : qui fait quoi et quand (UTC pour éviter les bugs de fuseau)
  final Map<DateTime, List<Map<String, dynamic>>> _events = {
    DateTime.utc(2025, 11, 24): [
      {'person': 'Kevin', 'task': 'Vaisselle', 'icon': Icons.local_laundry_service},
      {'person': 'Toi', 'task': 'Poubelles', 'icon': Icons.delete_outline},
    ],
    DateTime.utc(2025, 11, 25): [
      {'person': 'Marie', 'task': 'Salle de bain', 'icon': Icons.cleaning_services},
    ],
    DateTime.utc(2025, 11, 26): [
      {'person': 'Léo', 'task': 'Aspirateur', 'icon': Icons.air},
    ],
    DateTime.utc(2025, 11, 28): [
      {'person': 'Tout le monde', 'task': 'Courses', 'icon': Icons.shopping_cart_outlined},
    ],
  };

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7; // Lundi = 0

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Titre + mois
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  IconButton(onPressed: _previousMonth, icon: const Icon(Icons.chevron_left)),
                  Expanded(
                    child: Text(
                      "${_monthName(_focusedMonth.month)} ${_focusedMonth.year}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
                ],
              ),
            ),

            // Jours de la semaine
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                    .map((day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: primary),
                  ),
                ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Grille du mois
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.9,
                ),
                itemCount: daysInMonth + startingWeekday,
                itemBuilder: (context, index) {
                  if (index < startingWeekday) {
                    return const SizedBox();
                  }

                  final day = index - startingWeekday + 1;
                  final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                  final events = _getEventsForDay(date);
                  final isToday = date.year == DateTime.now().year &&
                      date.month == DateTime.now().month &&
                      date.day == DateTime.now().day;
                  final isSelected = _selectedDay != null &&
                      date.year == _selectedDay!.year &&
                      date.month == _selectedDay!.month &&
                      date.day == _selectedDay!.day;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = date),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withOpacity(0.2)
                            : (isToday ? primary.withOpacity(0.1) : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                        border: isToday ? Border.all(color: primary, width: 2) : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isToday || isSelected ? primary : null,
                              ),
                            ),
                          ),
                          if (events.isNotEmpty)
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                                child: Text(
                                  events.length.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Détail du jour sélectionné
            if (_selectedDay != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: theme.cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tâches du ${_formatDate(_selectedDay!)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ..._getEventsForDay(_selectedDay!).map((event) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(event['icon'], color: primary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event['task'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    "→ ${event['person']}",
                                    style: TextStyle(
                                      color: event['person'] == 'Toi' ? primary : null,
                                      fontWeight: event['person'] == 'Toi' ? FontWeight.bold : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (event['person'] == 'Toi') const Icon(Icons.star, color: Colors.amber),
                          ],
                        ),
                      );
                    }).toList(),
                    if (_getEventsForDay(_selectedDay!).isEmpty)
                      const Text("Aucune tâche ce jour-là", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ] else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, size: 60, color: primary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text("Tape sur un jour pour voir les tâches"),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    const days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    return "${days[date.weekday % 7]} ${date.day} ${_monthName(date.month)}";
  }
}