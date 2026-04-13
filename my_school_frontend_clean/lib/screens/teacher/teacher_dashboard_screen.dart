import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
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
  late String _currentClassName;
  List<String> _availableClasses = [];
  bool _isLoadingClasses = false;
  int _unreadMessages = 0;
  int _pendingWorks = 0;
  
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
    _currentClassName = widget.className;
    _loadTeacherClasses();
    _loadNotifications();
  }

  void _initPages() {
    _pages = [
      TeacherHomePage(
        teacherName: widget.teacherName,
        className: _currentClassName,
        unreadMessages: _unreadMessages,
        pendingWorks: _pendingWorks,
      ),
      TeacherLessonsScreen(
        teacherEmail: widget.email,
        className: _currentClassName,
      ),
      TeacherMessagesScreen(
        teacherEmail: widget.email,
        className: _currentClassName,
      ),
      TeacherClassScreen(
        teacherEmail: widget.email,
        className: _currentClassName,
      ),
      TeacherAgendaScreen(
        teacherEmail: widget.email,
        className: _currentClassName,
      ),
      TeacherProfileScreen(
        teacherEmail: widget.email,
        teacherName: widget.teacherName,
        className: _currentClassName,
      ),
    ];
  }

  void _updatePages() {
    setState(() {
      _pages = [
        TeacherHomePage(
          teacherName: widget.teacherName,
          className: _currentClassName,
          unreadMessages: _unreadMessages,
          pendingWorks: _pendingWorks,
        ),
        TeacherLessonsScreen(
          teacherEmail: widget.email,
          className: _currentClassName,
        ),
        TeacherMessagesScreen(
          teacherEmail: widget.email,
          className: _currentClassName,
        ),
        TeacherClassScreen(
          teacherEmail: widget.email,
          className: _currentClassName,
        ),
        TeacherAgendaScreen(
          teacherEmail: widget.email,
          className: _currentClassName,
        ),
        TeacherProfileScreen(
          teacherEmail: widget.email,
          teacherName: widget.teacherName,
          className: _currentClassName,
        ),
      ];
    });
  }

  Future<void> _loadNotifications() async {
    try {
      final result = await ApiService.getTeacherNotifications(widget.email);
      if (result['success']) {
        setState(() {
          _unreadMessages = result['unreadMessages'] ?? 0;
          _pendingWorks = result['pendingWorks'] ?? 0;
        });
      }
    } catch (e) {
      print('Erreur chargement notifications: $e');
      // Valeurs par défaut en cas d'erreur
      setState(() {
        _unreadMessages = 0;
        _pendingWorks = 0;
      });
    }
  }

  void _updateClassName(String newClassName) {
    setState(() {
      _currentClassName = newClassName;
    });
    _updatePages();
  }

  Future<void> _loadTeacherClasses() async {
    setState(() => _isLoadingClasses = true);
    
    try {
      final teacherInfo = await ApiService.getTeacherInfo(widget.email);
      
      List<String> classes = [];
      
      if (teacherInfo['success']) {
        if (teacherInfo.containsKey('classes') && teacherInfo['classes'] != null) {
          final classesData = teacherInfo['classes'];
          if (classesData is List) {
            classes = List<String>.from(classesData);
          } else if (classesData is String && classesData.contains(',')) {
            classes = classesData.split(',').map((c) => c.trim()).toList();
          } else if (classesData is String) {
            classes = [classesData];
          }
        }
        
        if (classes.isEmpty && teacherInfo.containsKey('className')) {
          classes = [teacherInfo['className'].toString()];
        }
      }
      
      if (classes.isEmpty) {
        classes = [widget.className];
      }
      
      setState(() {
        _availableClasses = classes;
        _isLoadingClasses = false;
      });
      
      _initPages();
      
    } catch (e) {
      print('❌ Erreur chargement classes: $e');
      setState(() {
        _availableClasses = [widget.className];
        _isLoadingClasses = false;
      });
      _initPages();
    }
  }

  void _showClassSelector() {
    if (_availableClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune classe disponible'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (_availableClasses.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vous êtes uniquement assigné à la classe ${_availableClasses[0]}'), backgroundColor: Colors.blue),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Changer de classe',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF01579B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enseignant: ${widget.teacherName}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  ..._availableClasses.map((className) {
                    final isCurrent = className == _currentClassName;
                    return ListTile(
                      leading: Icon(
                        isCurrent ? Icons.check_circle : Icons.class_,
                        color: isCurrent ? Colors.green : const Color(0xFF0288D1),
                      ),
                      title: Text(
                        className,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? Colors.green : Colors.black87,
                        ),
                      ),
                      trailing: isCurrent
                          ? const Chip(
                              label: Text('Actuelle'),
                              backgroundColor: Colors.green,
                              labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        if (className != _currentClassName) {
                          _updateClassName(className);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📚 Classe changée pour: $className'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.school,
                          color: Color(0xFF0288D1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'MySchool',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _isLoadingClasses ? null : _showClassSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _isLoadingClasses
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentClassName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                if (_availableClasses.length > 1) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Icon(
                              _menuItems[index]['icon'],
                              color: isSelected
                                  ? const Color(0xFF0288D1)
                                  : Colors.grey,
                              size: 20,
                            ),
                            if (index == 2 && _unreadMessages > 0)
                              Positioned(
                                right: -6,
                                top: -6,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 14,
                                    minHeight: 14,
                                  ),
                                  child: Text(
                                    '$_unreadMessages',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _menuItems[index]['label'],
                          style: TextStyle(
                            fontSize: 10,
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

// Page d'accueil - CORRIGÉE
class TeacherHomePage extends StatelessWidget {
  final String teacherName;
  final String className;
  final int unreadMessages;
  final int pendingWorks;

  const TeacherHomePage({
    super.key,
    required this.teacherName,
    required this.className,
    required this.unreadMessages,
    required this.pendingWorks,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de bienvenue
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📚 Bonjour, $teacherName !',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.class_,
                        size: 12,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        className,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Cartes de statistiques
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: 'Messages non lus',
                    value: '$unreadMessages',
                    icon: Icons.message,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    title: 'Travaux à corriger',
                    value: '$pendingWorks',
                    icon: Icons.assignment,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Agenda du jour
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📅 AUJOURD\'HUI',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF01579B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildScheduleItem('08:30 - 10:00', 'Maths', 'Salle 201'),
                  _buildScheduleItem('10:15 - 11:45', 'Maths', 'Salle 201'),
                  _buildScheduleItem('14:00 - 15:30', 'Français', 'Salle 105'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Rappels
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📌 RAPPELS IMPORTANTS',
                    style: TextStyle(
                      fontSize: 14,
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
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String time, String subject, String room) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              time,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Color(0xFF0288D1),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$subject - $room',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(String title, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$title: $date',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}