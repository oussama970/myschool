import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
// IMPORTS CORRIGÉS - sans préfixe teacher/
import 'teacher_agenda_screen.dart';
import 'teacher_lessons_screen.dart';
import 'teacher_class_screen.dart';
import 'teacher_messages_screen.dart';
import 'teacher_profile_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final String email;
  final String teacherName;
  final String className;

  const TeacherDashboardScreen({
    super.key,
    required this.email,
    required this.teacherName,
    required this.className,
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;
  
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'label': 'Accueil', 'page': 0},
    {'icon': Icons.menu_book, 'label': 'Cours', 'page': 1},
    {'icon': Icons.message, 'label': 'Messages', 'page': 2},
    {'icon': Icons.class_, 'label': 'Classe', 'page': 3},
    {'icon': Icons.calendar_today, 'label': 'Agenda', 'page': 4},
    {'icon': Icons.person, 'label': 'Profil', 'page': 5},
  ];

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      TeacherHomePage(
        teacherName: widget.teacherName,
        className: widget.className,
        unreadMessages: 3,
      ),
      TeacherLessonsScreen(
        teacherEmail: widget.email,
        className: widget.className,
      ),
      TeacherMessagesScreen(
        teacherEmail: widget.email,
        className: widget.className,
      ),
      TeacherClassScreen(
        teacherEmail: widget.email,
        className: widget.className,
      ),
      TeacherAgendaScreen(
        teacherEmail: widget.email,
        className: widget.className,
      ),
      TeacherProfileScreen(
        teacherEmail: widget.email,
        teacherName: widget.teacherName,
        className: widget.className,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.school,
                          color: Color(0xFF0288D1),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'MySchool',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.className,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenu principal
          Expanded(
            child: _pages[_selectedIndex],
          ),

          // Barre de navigation
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_menuItems.length, (index) {
                final isSelected = _selectedIndex == index;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _menuItems[index]['icon'],
                          color: isSelected
                              ? const Color(0xFF0288D1)
                              : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _menuItems[index]['label'],
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? const Color(0xFF0288D1)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// Page d'accueil
class TeacherHomePage extends StatelessWidget {
  final String teacherName;
  final String className;
  final int unreadMessages;

  const TeacherHomePage({
    super.key,
    required this.teacherName,
    required this.className,
    required this.unreadMessages,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📚 Bonjour, $teacherName !',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  className,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📅 AUJOURD\'HUI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF01579B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildScheduleItem('08:30 - 10:00', 'Maths', 'Salle 201'),
                _buildScheduleItem('10:15 - 11:45', 'Maths', 'Salle 201'),
                _buildScheduleItem('14:00 - 15:30', 'Français', 'Salle 105'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📌 RAPPELS IMPORTANTS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF01579B),
                  ),
                ),
                const SizedBox(height: 12),
                _buildReminderItem('Réunion parents-professeurs', '20/03 à 18h'),
                _buildReminderItem('Conseil de classe', '25/03'),
                _buildReminderItem('Sortie scolaire', '05/04'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String time, String subject, String room) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              time,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0288D1),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$subject - $room',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(String title, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title: $date',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}