import 'package:flutter/material.dart';
import 'admin_teachers_screen.dart';
import 'admin_parents_screen.dart';
import 'admin_students_screen.dart';

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
  late int _selectedTabIndex;
  
  final List<Map<String, dynamic>> _tabs = [
    {'icon': Icons.people, 'label': 'Enseignants'},
    {'icon': Icons.family_restroom, 'label': 'Parents'},
    {'icon': Icons.school, 'label': 'Élèves'},
  ];

  late List<Widget> _pages;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == index
                          ? const Color(0xFF0288D1).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _selectedTabIndex == index
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
                          color: _selectedTabIndex == index
                              ? const Color(0xFF0288D1)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _tabs[index]['label'],
                          style: TextStyle(
                            color: _selectedTabIndex == index
                                ? const Color(0xFF0288D1)
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: _pages[_selectedTabIndex],
        ),
      ],
    );
  }
}