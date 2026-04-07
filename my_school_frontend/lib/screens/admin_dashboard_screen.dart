import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/screens/login_screen.dart';
import 'admin_users_screen.dart';
import 'admin_classes_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_add_teacher_screen.dart';
import 'admin_add_class_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  
  // Statistiques
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
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                        child: Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.adminName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.email,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _menuItems[index]['icon'],
                          color: _selectedIndex == index
                              ? const Color(0xFF0288D1)
                              : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _menuItems[index]['label'],
                          style: TextStyle(
                            fontSize: 11,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Aperçu rapide
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 APERÇU RAPIDE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF01579B),
                  ),
                ),
                const SizedBox(height: 20),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      '👥 Enseignants',
                      '$totalTeachers',
                      '$pendingTeachers en attente',
                      Colors.orange,
                      onTap: onViewTeachers,
                    ),
                    _buildStatCard(
                      '👨‍👩‍👧 Parents',
                      '$totalParents',
                      totalStudents > 0 
                          ? '${((totalParents / totalStudents) * 100).toInt()}% connectés'
                          : '0% connectés',
                      Colors.green,
                      onTap: onViewParents,
                    ),
                    _buildStatCard(
                      '🧑‍🎓 Élèves',
                      '$totalStudents',
                      totalStudents > 0
                          ? '${(totalStudents / 25).ceil()} classes'
                          : '0 classes',
                      Colors.blue,
                      onTap: onViewStudents,
                    ),
                    _buildStatCard(
                      '🏫 Classes',
                      '$totalClasses',
                      'Active',
                      Colors.purple,
                      onTap: onViewClasses,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (pendingTeachers > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        '⚠️ ALERTES RÉCENTES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$pendingTeachers enseignant(s) en attente de validation',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        TextButton(
                          onPressed: onViewTeachers,
                          child: const Text('Voir'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Actions rapides
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚡ ACTIONS RAPIDES',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF01579B),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Ajouter\nenseignant',
                        Icons.person_add,
                        Colors.orange,
                        onAddTeacher,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        'Nouvelle\nclasse',
                        Icons.add_box,
                        Colors.green,
                        onAddClass,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Activité récente
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📈 ACTIVITÉ RÉCENTE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF01579B),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildActivityItem(
                  'Nouvel enseignant ajouté',
                  'Sophie Martin - Maths',
                  'Il y a 2 heures',
                  Icons.person_add,
                  Colors.green,
                ),
                
                const Divider(),
                
                _buildActivityItem(
                  'Classe créée',
                  'CE2 B',
                  'Il y a 5 heures',
                  Icons.add_box,
                  Colors.blue,
                ),
                
                const Divider(),
                
                _buildActivityItem(
                  'Parent lié',
                  'Marc Dupont → Chloé (CE2 A)',
                  'Il y a 1 jour',
                  Icons.family_restroom,
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}