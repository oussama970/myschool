import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'teacher_lessons_screen.dart';
import 'teacher_messages_screen.dart';
import 'teacher_class_screen.dart';
import 'teacher_devoir_screen.dart';
import 'teacher_profile_screen.dart';
import 'teacher_events_screen.dart';

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
  int _pendingEvents = 0;
  String _teacherId = '';
  String _teacherSubject = '';
  List<String> _teacherSubjects = [];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'label': 'Accueil', 'page': 0},
    {'icon': Icons.menu_book, 'label': 'Cours', 'page': 1},
    {'icon': Icons.message, 'label': 'Messages', 'page': 2},
    {'icon': Icons.class_, 'label': 'Classe', 'page': 3},
    {'icon': Icons.calendar_today, 'label': 'Devoirs', 'page': 4},
    {'icon': Icons.event, 'label': 'Événements', 'page': 5},
    {'icon': Icons.person, 'label': 'Profil', 'page': 6},
  ];

  // 👈 CHANGEMENT: initialisation directe au lieu de 'late'
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _currentClassName = widget.className;
    // Initialisation temporaire pour éviter l'erreur
    _pages = [const Center(child: CircularProgressIndicator())];
    _loadTeacherInfo();
    _loadTeacherClasses();
    _loadNotifications();
  }

  Future<void> _loadTeacherInfo() async {
    try {
      final result = await ApiService.getTeacherInfo(widget.email);
      if (result['success']) {
        setState(() {
          _teacherId = result['teacherId'] ?? '';
          _teacherSubjects = List<String>.from(result['subjects'] ?? []);
          if (_teacherSubjects.isNotEmpty) {
            _teacherSubject = _teacherSubjects[0];
          }
        });
        print('✅ ID Enseignant: $_teacherId');
        print('✅ Matières: $_teacherSubjects');
      }
    } catch (e) {
      print('❌ Erreur chargement ID enseignant: $e');
    }
  }

  void _initPages() {
    _pages = [
      TeacherHomePage(
        teacherName: widget.teacherName,
        className: _currentClassName,
        teacherSubject: _teacherSubject,
        onAddCourse: () => _navigateToAddCourse(),
        onAddHomework: () => _navigateToAddHomework(),
        onGoToMessages: () => _navigateToMessages(),
        onGoToClass: () => _navigateToClass(),
        onGoToProfile: () => _navigateToProfile(),
        onGoToEvents: () => _navigateToEvents(),
      ),
      TeacherLessonsScreen(
        teacherEmail: widget.email,
        className: _currentClassName,
        teacherSubject: _teacherSubject,
      ),
      TeacherMessagesScreen(
        teacherEmail: widget.email,
        className: _currentClassName,
        teacherId: _teacherId,
        onUnreadCountChanged: _updateUnreadMessagesCount,
      ),
      TeacherClassScreen(
        teacherEmail: widget.email,
        className: _currentClassName,
        teacherId: _teacherId,
        teacherName: widget.teacherName,
        teacherSubject: _teacherSubject,
      ),
      TeacherDevoirScreen(
        teacherEmail: widget.email,
        className: _currentClassName,
        teacherId: _teacherId,
        teacherSubject: _teacherSubject,
        teacherName: widget.teacherName,
      ),
      TeacherEventsScreen(
        teacherId: _teacherId,
        teacherName: widget.teacherName,
        className: _currentClassName,
      ),
      TeacherProfileScreen(
        teacherEmail: widget.email,
        teacherName: widget.teacherName,
        className: _currentClassName,
      ),
    ];
    setState(() {});
  }

  void _navigateToAddCourse() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _navigateToAddHomework() {
    setState(() {
      _selectedIndex = 4;
    });
  }

  void _navigateToMessages() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  void _navigateToClass() {
    setState(() {
      _selectedIndex = 3;
    });
  }

  void _navigateToProfile() {
    setState(() {
      _selectedIndex = 6;
    });
  }

  void _navigateToEvents() {
    setState(() {
      _selectedIndex = 5;
    });
  }

  void _updateUnreadMessagesCount(int count) {
    if (mounted) {
      setState(() {
        _unreadMessages = count;
      });
    }
  }

  void _updatePages() {
    _pages = [
      TeacherHomePage(
        teacherName: widget.teacherName,
        className: _currentClassName,
        teacherSubject: _teacherSubject,
        onAddCourse: () => _navigateToAddCourse(),
        onAddHomework: () => _navigateToAddHomework(),
        onGoToMessages: () => _navigateToMessages(),
        onGoToClass: () => _navigateToClass(),
        onGoToProfile: () => _navigateToProfile(),
        onGoToEvents: () => _navigateToEvents(),
      ),
      TeacherLessonsScreen(
        teacherEmail: widget.email,
        className: _currentClassName,
        teacherSubject: _teacherSubject,
      ),
      TeacherMessagesScreen(
        teacherEmail: widget.email,
        className: _currentClassName,
        teacherId: _teacherId,
        onUnreadCountChanged: _updateUnreadMessagesCount,
      ),
      TeacherClassScreen(
        teacherEmail: widget.email,
        className: _currentClassName,
        teacherId: _teacherId,
        teacherName: widget.teacherName,
        teacherSubject: _teacherSubject,
      ),
      TeacherDevoirScreen(
        teacherEmail: widget.email,
        className: _currentClassName,
        teacherId: _teacherId,
        teacherSubject: _teacherSubject,
        teacherName: widget.teacherName,
      ),
      TeacherEventsScreen(
        teacherId: _teacherId,
        teacherName: widget.teacherName,
        className: _currentClassName,
      ),
      TeacherProfileScreen(
        teacherEmail: widget.email,
        teacherName: widget.teacherName,
        className: _currentClassName,
      ),
    ];
    setState(() {});
  }

  Future<void> _loadNotifications() async {
    try {
      final result = await ApiService.getTeacherNotifications(widget.email);
      if (result['success']) {
        setState(() {
          _unreadMessages = result['unreadMessages'] ?? 0;
          _pendingWorks = result['pendingWorks'] ?? 0;
          _pendingEvents = result['pendingEvents'] ?? 0;
        });
      }
    } catch (e) {
      print('Erreur chargement notifications: $e');
      setState(() {
        _unreadMessages = 0;
        _pendingWorks = 0;
        _pendingEvents = 0;
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

          // Contenu principal
          Expanded(
            child: _pages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _pages[_selectedIndex],
          ),

          // Bottom Navigation Bar
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
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              _menuItems[index]['icon'],
                              color: isSelected
                                  ? const Color(0xFF0288D1)
                                  : Colors.grey,
                              size: 24,
                            ),
                            // Badge pour les messages non lus
                            if (index == 2 && _unreadMessages > 0)
                              Positioned(
                                right: -8,
                                top: -8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    _unreadMessages > 9 ? '9+' : '$_unreadMessages',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            // Badge pour les événements en attente
                            if (index == 5 && _pendingEvents > 0)
                              Positioned(
                                right: -8,
                                top: -8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    _pendingEvents > 9 ? '9+' : '$_pendingEvents',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
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
  final String teacherSubject;
  final VoidCallback onAddCourse;
  final VoidCallback onAddHomework;
  final VoidCallback onGoToMessages;
  final VoidCallback onGoToClass;
  final VoidCallback onGoToProfile;
  final VoidCallback onGoToEvents;

  const TeacherHomePage({
    super.key,
    required this.teacherName,
    required this.className,
    required this.teacherSubject,
    required this.onAddCourse,
    required this.onAddHomework,
    required this.onGoToMessages,
    required this.onGoToClass,
    required this.onGoToProfile,
    required this.onGoToEvents,
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF0288D1),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour,',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              teacherName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.class_,
                          label: 'Classe',
                          value: className,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.menu_book,
                          label: 'Matière',
                          value: teacherSubject,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu rapide
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📱 Menu rapide',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF01579B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuItem(
                          icon: Icons.add_circle_outline,
                          label: 'Cours',
                          color: const Color(0xFF0288D1),
                          onTap: onAddCourse,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMenuItem(
                          icon: Icons.calendar_today,
                          label: 'Devoir',
                          color: Colors.orange,
                          onTap: onAddHomework,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMenuItem(
                          icon: Icons.message,
                          label: 'Messages',
                          color: Colors.green,
                          onTap: onGoToMessages,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuItem(
                          icon: Icons.class_,
                          label: 'Classe',
                          color: const Color(0xFF4CAF9F),
                          onTap: onGoToClass,
                        ),
                      ),
                      Expanded(
                        child: _buildMenuItem(
                          icon: Icons.event,
                          label: 'Événements',
                          color: const Color(0xFFFF9800),
                          onTap: onGoToEvents,
                        ),
                      ),
                      Expanded(
                        child: _buildMenuItem(
                          icon: Icons.person,
                          label: 'Profil',
                          color: const Color(0xFF9C27B0),
                          onTap: onGoToProfile,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Informations supplémentaires
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ℹ️ À propos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF01579B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAboutItem(
                    icon: Icons.school,
                    title: 'Plateforme éducative',
                    description: 'Gérez vos cours, devoirs et communications',
                  ),
                  const Divider(height: 24),
                  _buildAboutItem(
                    icon: Icons.people,
                    title: 'Communication',
                    description: 'Échangez avec les élèves et les parents',
                  ),
                  const Divider(height: 24),
                  _buildAboutItem(
                    icon: Icons.analytics,
                    title: 'Suivi pédagogique',
                    description: 'Notes, absences et progression des élèves',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0288D1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0288D1), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF01579B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}