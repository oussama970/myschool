import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/screens/auth/login_screen.dart';
import 'admin_users_screen.dart';
import 'admin_classes_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_add_teacher_screen.dart';
import 'admin_add_class_screen.dart';
import 'admin_schedule_screen.dart';

/// Tableau de bord principal de l'administrateur
/// Affiche les statistiques et permet d'accéder à toutes les fonctionnalités d'administration
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
  // ==================== VARIABLES D'ÉTAT ====================
  int _selectedIndex = 0;
  
  // Statistiques
  int _totalTeachers = 0;
  int _totalParents = 0;
  int _totalStudents = 0;
  int _pendingTeachers = 0;
  int _totalClasses = 0;
  bool _isLoading = true;

  // Menu de navigation
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'label': 'Accueil', 'page': 0},
    {'icon': Icons.people, 'label': 'Utilisateurs', 'page': 1},
    {'icon': Icons.class_, 'label': 'Classes', 'page': 2},
    {'icon': Icons.bar_chart, 'label': 'Statistiques', 'page': 3},
    {'icon': Icons.calendar_month, 'label': 'Emploi', 'page': 4},
    {'icon': Icons.person, 'label': 'Profil', 'page': 5},
  ];

  late List<Widget> _pages;

  // ==================== CYCLE DE VIE ====================
  
  @override
  void initState() {
    super.initState();
    _loadStats();
    _initPages();
  }

  /// Initialise les pages avec les valeurs par défaut
  void _initPages() {
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
      AdminScheduleScreen(adminEmail: widget.email),
      AdminProfileScreen(adminEmail: widget.email, adminName: widget.adminName),
    ];
  }

  // ==================== CHARGEMENT DES DONNÉES ====================
  
  /// Charge les statistiques depuis l'API
  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getDashboardStats();
      
      if (result['success']) {
        final stats = result['stats'];
        setState(() {
          _totalTeachers = stats['totalTeachers'] ?? 0;
          _totalParents = stats['totalParents'] ?? 0;
          _totalStudents = stats['totalStudents'] ?? 0;
          _pendingTeachers = stats['pendingTeachers'] ?? 0;
          _totalClasses = stats['totalClasses'] ?? 0;
          _isLoading = false;
        });
        
        _updateHomePage();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Exception: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Met à jour la page d'accueil avec les nouvelles statistiques
  void _updateHomePage() {
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
  }

  // ==================== NAVIGATION ====================
  
  /// Navigue vers l'écran d'ajout d'enseignant
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

  /// Navigue vers l'écran d'ajout de classe
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

  /// Change la page sélectionnée
  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Navigue vers un onglet spécifique de la page utilisateurs
  void _navigateToUsersTab(int tabIndex) {
    setState(() {
      _selectedIndex = 1;
      _pages[1] = AdminUsersScreen(
        adminEmail: widget.email,
        initialTab: tabIndex,
      );
    });
  }

  // ==================== BUILD UI ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // En-tête avec logo et nom admin
          _buildHeader(),
          
          // Contenu principal
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pages[_selectedIndex],
          ),
          
          // Barre de navigation inférieure
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  /// Construit l'en-tête de l'application
  Widget _buildHeader() {
    return Container(
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
            // Logo
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
            // Nom de l'administrateur
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
    );
  }

  /// Construit la barre de navigation inférieure
  Widget _buildBottomNavBar() {
    return Container(
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
                  Icon(
                    _menuItems[index]['icon'],
                    color: isSelected
                        ? const Color(0xFF0288D1)
                        : Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(height: 2),
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
    );
  }
}

// ==================== PAGE D'ACCUEIL ADMIN ====================

/// Page d'accueil du tableau de bord administrateur
/// Affiche les statistiques et les actions rapides
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
    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Carte de bienvenue
            _buildWelcomeCard(),
            
            const SizedBox(height: 12),
            
            // Grille des statistiques
            _buildStatsGrid(),
            
            const SizedBox(height: 12),
            
            // Alerte enseignants en attente
            if (pendingTeachers > 0) _buildPendingTeachersAlert(),
            
            const SizedBox(height: 12),
            
            // Actions rapides
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  /// Carte de bienvenue avec date
  Widget _buildWelcomeCard() {
    return Container(
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Grille des statistiques (4 cartes)
  Widget _buildStatsGrid() {
    return GridView.count(
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
    );
  }

  /// Carte de statistique individuelle
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

  /// Alerte pour les enseignants en attente de validation
  Widget _buildPendingTeachersAlert() {
    return Container(
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
    );
  }

  /// Actions rapides (ajout d'enseignant ou de classe)
  Widget _buildQuickActions() {
    return Container(
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
    );
  }

  /// Widget d'action rapide
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