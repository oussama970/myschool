import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/screens/login_screen.dart';
import 'admin_users_screen.dart';
import 'admin_classes_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_add_teacher_screen.dart';
import 'admin_add_class_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String email;
  final String adminName;

  const AdminDashboardScreen({
    super.key,
    required this.email,
    required this.adminName,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  
  int _totalTeachers = 0;
  int _totalParents = 0;
  int _totalStudents = 0;
  int _pendingTeachers = 0;
  int _totalClasses = 0;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'label': 'Accueil', 'page': 0},
    {'icon': Icons.people, 'label': 'Utilisateurs', 'page': 1},
    {'icon': Icons.class_, 'label': 'Classes', 'page': 2},
    {'icon': Icons.bar_chart, 'label': 'Statistiques', 'page': 3},
    {'icon': Icons.person, 'label': 'Profil', 'page': 4},
  ];

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _pages = [
      AdminHomePage(
        totalTeachers: _totalTeachers,
        totalParents: _totalParents,
        totalStudents: _totalStudents,
        pendingTeachers: _pendingTeachers,
        totalClasses: _totalClasses,
        onAddTeacher: _navigateToAddTeacher,
        onAddClass: _navigateToAddClass,
        onViewTeachers: () => _navigateToUsersTab(0),
        onViewParents: () => _navigateToUsersTab(1),
        onViewStudents: () => _navigateToUsersTab(2),
        onViewClasses: () => _navigateToPage(2),
      ),
      AdminUsersScreen(adminEmail: widget.email, initialTab: 0),
      AdminClassesScreen(adminEmail: widget.email),
      AdminStatsScreen(adminEmail: widget.email),
      AdminProfileScreen(adminEmail: widget.email, adminName: widget.adminName),
    ];
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getDashboardStats();
      
      if (result['success']) {
        setState(() {
          _totalTeachers = result['stats']['totalTeachers'] ?? 0;
          _totalParents = result['stats']['totalParents'] ?? 0;
          _totalStudents = result['stats']['totalStudents'] ?? 0;
          _pendingTeachers = result['stats']['pendingTeachers'] ?? 0;
          _totalClasses = result['stats']['totalClasses'] ?? 0;
          _isLoading = false;
        });
        
        // Mettre à jour la page d'accueil
        _pages[0] = AdminHomePage(
          totalTeachers: _totalTeachers,
          totalParents: _totalParents,
          totalStudents: _totalStudents,
          pendingTeachers: _pendingTeachers,
          totalClasses: _totalClasses,
          onAddTeacher: _navigateToAddTeacher,
          onAddClass: _navigateToAddClass,
          onViewTeachers: () => _navigateToUsersTab(0),
          onViewParents: () => _navigateToUsersTab(1),
          onViewStudents: () => _navigateToUsersTab(2),
          onViewClasses: () => _navigateToPage(2),
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToAddTeacher() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAddTeacherScreen(adminEmail: widget.email),
      ),
    );
    if (result == true) {
      _loadStats();
      setState(() {
        _pages[1] = AdminUsersScreen(adminEmail: widget.email, initialTab: 0);
      });
    }
  }

  void _navigateToAddClass() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAddClassScreen(adminEmail: widget.email),
      ),
    );
    if (result == true) {
      _loadStats();
      setState(() {
        _pages[2] = AdminClassesScreen(adminEmail: widget.email);
      });
    }
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToUsersTab(int tabIndex) {
    setState(() {
      _selectedIndex = 1;
      _pages[1] = AdminUsersScreen(
        adminEmail: widget.email,
        initialTab: tabIndex,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // En-tête avec dégradé bleu
          Container(
            padding: const EdgeInsets.all(16),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.adminName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

          // Barre de navigation en bas
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
                        Icon(
                          _menuItems[index]['icon'],
                          color: _selectedIndex == index
                              ? const Color(0xFF0288D1)
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _menuItems[index]['label'],
                          style: TextStyle(
                            fontSize: 10,
                            color: _selectedIndex == index
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

// Page d'accueil avec aperçu rapide
class AdminHomePage extends StatelessWidget {
  final int totalTeachers;
  final int totalParents;
  final int totalStudents;
  final int pendingTeachers;
  final int totalClasses;
  final VoidCallback onAddTeacher;
  final VoidCallback onAddClass;
  final VoidCallback onViewTeachers;
  final VoidCallback onViewParents;
  final VoidCallback onViewStudents;
  final VoidCallback onViewClasses;

  const AdminHomePage({
    super.key,
    required this.totalTeachers,
    required this.totalParents,
    required this.totalStudents,
    required this.pendingTeachers,
    required this.totalClasses,
    required this.onAddTeacher,
    required this.onAddClass,
    required this.onViewTeachers,
    required this.onViewParents,
    required this.onViewStudents,
    required this.onViewClasses,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
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
                const Text(
                  'Bienvenue 👋',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gérez votre établissement scolaire',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Statistiques
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                title: 'Enseignants',
                value: '$totalTeachers',
                icon: Icons.people,
                color: const Color(0xFF0288D1),
                onTap: onViewTeachers,
              ),
              _buildStatCard(
                title: 'Élèves',
                value: '$totalStudents',
                icon: Icons.school,
                color: const Color(0xFF4CAF9F),
                onTap: onViewStudents,
              ),
              _buildStatCard(
                title: 'Classes',
                value: '$totalClasses',
                icon: Icons.class_,
                color: const Color(0xFFFF9800),
                onTap: onViewClasses,
              ),
              _buildStatCard(
                title: 'Parents',
                value: '$totalParents',
                icon: Icons.family_restroom,
                color: const Color(0xFF9C27B0),
                onTap: onViewParents,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Alertes
          if (pendingTeachers > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning, color: Colors.orange, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enseignants en attente',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '$pendingTeachers enseignant(s) à valider',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onViewTeachers,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('VALIDER', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Actions rapides
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
                  '⚡ Actions rapides',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF01579B),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.person_add,
                        label: 'Enseignant',
                        color: Colors.orange,
                        onTap: onAddTeacher,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.add_box,
                        label: 'Classe',
                        color: Colors.green,
                        onTap: onAddClass,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
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
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}