import 'package:flutter/material.dart';
import 'admin_teachers_screen.dart';
import 'admin_parents_screen.dart';
import 'admin_students_screen.dart';

/// Écran de gestion des utilisateurs pour l'administrateur
/// Permet de naviguer entre trois onglets : Enseignants, Parents, Élèves
class AdminUsersScreen extends StatefulWidget {
  final String adminEmail;
  final int initialTab;

  const AdminUsersScreen({
    super.key,
    required this.adminEmail,
    this.initialTab = 0,
  });

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  // ==================== VARIABLES D'ÉTAT ====================
  late int _selectedTabIndex;
  
  // Liste des onglets avec icône et label
  final List<Map<String, dynamic>> _tabs = [
    {'icon': Icons.people, 'label': 'Enseignants'},
    {'icon': Icons.family_restroom, 'label': 'Parents'},
    {'icon': Icons.school, 'label': 'Élèves'},
  ];

  late List<Widget> _pages;

  // ==================== CYCLE DE VIE ====================
  
  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTab;
    _pages = [
      AdminTeachersScreen(adminEmail: widget.adminEmail),
      AdminParentsScreen(adminEmail: widget.adminEmail),
      AdminStudentsScreen(adminEmail: widget.adminEmail),
    ];
  }

  // ==================== BUILD UI ====================
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre d'onglets
        _buildTabBar(),
        
        // Contenu de l'onglet sélectionné
        Expanded(
          child: _pages[_selectedTabIndex],
        ),
      ],
    );
  }

  /// Construit la barre d'onglets avec les icônes et labels
  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: _buildTabButton(index, isSelected),
          );
        }),
      ),
    );
  }

  /// Construit un bouton d'onglet individuel
  Widget _buildTabButton(int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0288D1).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0288D1)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _tabs[index]['icon'],
              size: 18,
              color: isSelected ? const Color(0xFF0288D1) : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              _tabs[index]['label'],
              style: TextStyle(
                color: isSelected ? const Color(0xFF0288D1) : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}