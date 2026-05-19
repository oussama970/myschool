// lib/screens/student/student_dashboard_screen.dart (version corrigée)

import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'student_courses_screen.dart';
import 'student_grades_screen.dart';
import 'student_absences_screen.dart';
import 'student_events_screen.dart';
import 'student_schedule_screen.dart';
import 'student_messages_screen.dart';
import 'student_profile_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String email;
  final String studentName;
  final bool isParent;
  final String? parentEmail;

  const StudentDashboardScreen({
    super.key,
    required this.email,
    required this.studentName,
    this.isParent = false,
    this.parentEmail,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;
  String _studentClass = '';
  String _studentId = '';
  bool _isLoading = true;
  int _pendingEvents = 0;
  int _pendingHomeworks = 0;
  double _averageGrade = 0;
  int _totalAbsences = 0;
  List<Map<String, dynamic>> _todaySchedule = [];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'label': 'Accueil', 'page': 0},
    {'icon': Icons.menu_book, 'label': 'Cours', 'page': 1},
    {'icon': Icons.grade, 'label': 'Notes', 'page': 2},
    {'icon': Icons.event_busy, 'label': 'Absences', 'page': 3},
    {'icon': Icons.event, 'label': 'Événements', 'page': 4},
    {'icon': Icons.calendar_month, 'label': 'Emploi', 'page': 5},
    {'icon': Icons.message, 'label': 'Messages', 'page': 6},
    {'icon': Icons.person, 'label': 'Profil', 'page': 7},
  ];

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initializePages(); // Initialiser les pages avec des valeurs par défaut
    _loadStudentInfo();
  }

  void _initializePages() {
    // Initialiser les pages avec des valeurs par défaut
    _pages = [
      StudentHomePage(
        studentName: widget.studentName,
        studentClass: _studentClass.isEmpty ? 'Chargement...' : _studentClass,
        averageGrade: _averageGrade,
        totalAbsences: _totalAbsences,
        pendingEvents: _pendingEvents,
        pendingHomeworks: _pendingHomeworks,
        todaySchedule: _todaySchedule,
        onViewCourses: () => _navigateToPage(1),
        onViewGrades: () => _navigateToPage(2),
        onViewAbsences: () => _navigateToPage(3),
        onViewEvents: () => _navigateToPage(4),
        onViewSchedule: () => _navigateToPage(5),
        onViewMessages: () => _navigateToPage(6),
      ),
      StudentCoursesScreen(studentId: _studentId, studentName: widget.studentName, studentClass: _studentClass),
      StudentGradesScreen(studentId: _studentId, studentName: widget.studentName, studentClass: _studentClass),
      StudentAbsencesScreen(studentId: _studentId, studentName: widget.studentName, studentClass: _studentClass),
      StudentEventsScreen(studentId: _studentId, studentName: widget.studentName, studentClass: _studentClass),
      StudentScheduleScreen(studentClass: _studentClass),
      StudentMessagesScreen(studentId: _studentId, studentName: widget.studentName, studentClass: _studentClass),
      StudentProfileScreen(studentEmail: widget.email, studentName: widget.studentName, studentClass: _studentClass),
    ];
  }

  void _updatePages() {
    // Mettre à jour les pages avec les données chargées
    setState(() {
      _pages = [
        StudentHomePage(
          studentName: widget.studentName,
          studentClass: _studentClass.isEmpty ? 'Non assigné' : _studentClass,
          averageGrade: _averageGrade,
          totalAbsences: _totalAbsences,
          pendingEvents: _pendingEvents,
          pendingHomeworks: _pendingHomeworks,
          todaySchedule: _todaySchedule,
          onViewCourses: () => _navigateToPage(1),
          onViewGrades: () => _navigateToPage(2),
          onViewAbsences: () => _navigateToPage(3),
          onViewEvents: () => _navigateToPage(4),
          onViewSchedule: () => _navigateToPage(5),
          onViewMessages: () => _navigateToPage(6),
        ),
        StudentCoursesScreen(studentId: _studentId, studentName: widget.studentName, studentClass: _studentClass),
        StudentGradesScreen(studentId: _studentId, studentName: widget.studentName, studentClass: _studentClass),
        StudentAbsencesScreen(studentId: _studentId, studentName: widget.studentName, studentClass: _studentClass),
        StudentEventsScreen(studentId: _studentId, studentName: widget.studentName, studentClass: _studentClass),
        StudentScheduleScreen(studentClass: _studentClass),
        StudentMessagesScreen(studentId: _studentId, studentName: widget.studentName, studentClass: _studentClass),
        StudentProfileScreen(studentEmail: widget.email, studentName: widget.studentName, studentClass: _studentClass),
      ];
    });
  }

  Future<void> _loadStudentInfo() async {
    setState(() => _isLoading = true);
    try {
      print('📚 Chargement infos élève: ${widget.email}');
      final result = await ApiService.getStudentInfo(widget.email);
      print('📚 Résultat getStudentInfo: $result');
      
      if (result['success']) {
        setState(() {
          _studentId = result['studentId'] ?? widget.email;
          _studentClass = result['className'] ?? 'Non assigné';
        });
        
        await Future.wait([
          _loadAllStats(),
          _loadTodaySchedule(),
        ]);
        
        _updatePages(); // Mettre à jour les pages après chargement des données
      } else {
        print('❌ Erreur chargement infos: ${result['message']}');
      }
    } catch (e) {
      print('❌ Exception: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAllStats() async {
    await Future.wait([
      _loadPendingEvents(),
      _loadAverageGrade(),
      _loadAbsencesCount(),
      _loadPendingHomeworks(),
    ]);
  }

  Future<void> _loadTodaySchedule() async {
    try {
      print('📅 Chargement emploi du temps pour classe: $_studentClass');
      final result = await ApiService.getStudentSchedule(_studentClass);
      print('📅 Résultat schedule: ${result['success']}');
      
      if (result['success'] && result['schedule'] != null) {
        final schedule = result['schedule'];
        final now = DateTime.now();
        final days = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa'];
        final todayIndex = now.weekday - 1;
        
        if (todayIndex >= 0 && todayIndex < days.length) {
          final today = days[todayIndex];
          final todaySlots = schedule[today];
          
          if (todaySlots != null) {
            final List<Map<String, dynamic>> slots = [];
            for (int i = 0; i < 5; i++) {
              final slot = todaySlots[i.toString()];
              if (slot != null && slot['subject'] != null && slot['subject'].toString().isNotEmpty) {
                slots.add({
                  'timeSlot': _getTimeSlot(i),
                  'subject': slot['subject'],
                  'teacher': slot['teacher'],
                  'room': slot['room'],
                });
              }
            }
            setState(() {
              _todaySchedule = slots;
            });
            print('📅 Cours du jour trouvés: ${slots.length}');
          }
        }
      }
    } catch (e) {
      print('❌ Erreur chargement emploi du temps: $e');
    }
  }

  String _getTimeSlot(int index) {
    const slots = ['8h-9h', '9h-10h', '10h-11h', '11h-12h', '12h-13h'];
    return slots[index];
  }

  Future<void> _loadPendingEvents() async {
    try {
      final result = await ApiService.getParentEvents(_studentId);
      if (result['success']) {
        final events = result['events'] ?? [];
        setState(() {
          _pendingEvents = events.where((e) => e['myResponse'] == 'pending').length;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement événements: $e');
    }
  }

  Future<void> _loadPendingHomeworks() async {
    try {
      final result = await ApiService.getStudentLessons(_studentClass);
      if (result['success']) {
        final lessons = result['lessons'] ?? [];
        final homeworks = lessons.where((l) => l['type'] == 'Devoir').toList();
        setState(() {
          _pendingHomeworks = homeworks.length;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement devoirs: $e');
    }
  }

  Future<void> _loadAverageGrade() async {
    try {
      final result = await ApiService.getStudentExamGrades(_studentId);
      if (result['success']) {
        final grades = result['grades'] ?? [];
        if (grades.isNotEmpty) {
          double sum = 0;
          for (var grade in grades) {
            sum += (grade['grade'] ?? 0);
          }
          setState(() {
            _averageGrade = sum / grades.length;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur chargement moyenne: $e');
    }
  }

  Future<void> _loadAbsencesCount() async {
    try {
      final result = await ApiService.getStudentAbsencesForParent(_studentId);
      if (result['success']) {
        final absences = result['absences'] ?? [];
        setState(() {
          _totalAbsences = absences.length;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement absences: $e');
    }
  }

  void _navigateToPage(int index) {
    print('🔄 Navigation vers page: $index');
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.isParent ? 'Espace de ${widget.studentName}' : 'Mon espace'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.isParent)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Déconnexion'),
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'logout') {
                  ApiService.logout();
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pages.isNotEmpty ? _pages[_selectedIndex] : const Center(child: Text('Erreur de chargement')),
      bottomNavigationBar: _isLoading ? null : Container(
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
              onTap: () => _navigateToPage(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          _menuItems[index]['icon'],
                          color: isSelected ? const Color(0xFF0288D1) : Colors.grey,
                          size: 22,
                        ),
                        if (index == 4 && _pendingEvents > 0)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                _pendingEvents > 9 ? '9+' : '$_pendingEvents',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _menuItems[index]['label'],
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? const Color(0xFF0288D1) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// Page d'accueil élève (reste identique)
class StudentHomePage extends StatelessWidget {
  final String studentName;
  final String studentClass;
  final double averageGrade;
  final int totalAbsences;
  final int pendingEvents;
  final int pendingHomeworks;
  final List<Map<String, dynamic>> todaySchedule;
  final VoidCallback onViewCourses;
  final VoidCallback onViewGrades;
  final VoidCallback onViewAbsences;
  final VoidCallback onViewEvents;
  final VoidCallback onViewSchedule;
  final VoidCallback onViewMessages;

  const StudentHomePage({
    super.key,
    required this.studentName,
    required this.studentClass,
    required this.averageGrade,
    required this.totalAbsences,
    required this.pendingEvents,
    required this.pendingHomeworks,
    required this.todaySchedule,
    required this.onViewCourses,
    required this.onViewGrades,
    required this.onViewAbsences,
    required this.onViewEvents,
    required this.onViewSchedule,
    required this.onViewMessages,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
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
                  Text('Bonjour,', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                  Text(studentName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(Icons.class_, studentClass, 'Classe', Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(Icons.grade, averageGrade > 0 ? averageGrade.toStringAsFixed(1) : '-', 'Moyenne', Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(Icons.event_busy, '$totalAbsences', 'Absences', Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(Icons.assignment, '$pendingHomeworks', 'Devoirs', Colors.white)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📅 EMPLOI DU TEMPS AUJOURD\'HUI',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
                      ),
                      TextButton.icon(
                        onPressed: onViewSchedule,
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: const Text('Voir tout'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0288D1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (todaySchedule.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Aucun cours aujourd\'hui',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...todaySchedule.map((course) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0288D1).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0288D1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                course['timeSlot'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0288D1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course['subject'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Salle ${course['room']} - ${course['teacher']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📱 ACCÈS RAPIDE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF01579B))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildMenuItem(Icons.menu_book, 'Cours', const Color(0xFF0288D1), onViewCourses)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMenuItem(Icons.grade, 'Notes', const Color(0xFF4CAF9F), onViewGrades)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMenuItem(Icons.event_busy, 'Absences', Colors.red, onViewAbsences)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMenuItem(Icons.event, 'Événements', Colors.orange, onViewEvents)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMenuItem(Icons.calendar_month, 'Emploi', const Color(0xFF0288D1), onViewSchedule)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMenuItem(Icons.message, 'Messages', const Color(0xFF4CAF9F), onViewMessages)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}