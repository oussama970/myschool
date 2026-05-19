// lib/screens/parent/parent_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/models/child_model.dart';
import 'parent_courses_screen.dart';
import 'parent_grades_screen.dart';
import 'parent_absences_screen.dart';
import 'parent_events_screen.dart';
import 'parent_messages_screen.dart';
import 'parent_profile_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  final String parentEmail;
  final String parentName;

  const ParentDashboardScreen({
    super.key,
    required this.parentEmail,
    required this.parentName,
  });

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  int _selectedIndex = 0;
  List<ChildModel> _children = [];
  ChildModel? _selectedChild;
  bool _isLoading = true;
  
  int _pendingEvents = 0;
  String _selectedChildClass = '';

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'label': 'Accueil', 'page': 0},
    {'icon': Icons.menu_book, 'label': 'Cours', 'page': 1},
    {'icon': Icons.grade, 'label': 'Notes', 'page': 2},
    {'icon': Icons.event_busy, 'label': 'Absences', 'page': 3},
    {'icon': Icons.event, 'label': 'Événements', 'page': 4},
    {'icon': Icons.message, 'label': 'Messages', 'page': 5},
    {'icon': Icons.person, 'label': 'Profil', 'page': 6},
  ];

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getParentChildren(widget.parentEmail);
      if (result['success'] && mounted) {
        final List<dynamic> childrenData = result['children'] ?? [];
        setState(() {
          _children = childrenData.map((c) => ChildModel.fromJson(c)).toList();
          if (_children.isNotEmpty) {
            _selectedChild = _children[0];
            _selectedChildClass = _selectedChild!.className;
          }
          _isLoading = false;
        });
        _initPages();
        await _loadNotifications();
      } else {
        setState(() => _isLoading = false);
        _initPages();
      }
    } catch (e) {
      print('❌ Erreur: $e');
      setState(() => _isLoading = false);
      _initPages();
    }
  }

  Future<void> _loadNotifications() async {
    if (_selectedChild == null) return;
    try {
      final eventsResult = await ApiService.getParentEvents(_selectedChild!.id);
      if (eventsResult['success']) {
        final events = eventsResult['events'] ?? [];
        setState(() {
          _pendingEvents = events.where((e) => e['myResponse'] == 'pending').length;
        });
      }
    } catch (e) {
      print('Erreur notifications: $e');
    }
  }

  void _initPages() {
    _pages = [
      ParentHomePage(
        parentName: widget.parentName,
        childrenCount: _children.length,
        selectedChildName: _selectedChild?.fullName ?? '',
        selectedChildClass: _selectedChildClass,
        pendingEvents: _pendingEvents,
        onViewCourses: () => _navigateToPage(1),
        onViewGrades: () => _navigateToPage(2),
        onViewAbsences: () => _navigateToPage(3),
        onViewEvents: () => _navigateToPage(4),
        onViewMessages: () => _navigateToPage(5),
      ),
      ParentCoursesScreen(selectedChild: _selectedChild),
      ParentGradesScreen(selectedChild: _selectedChild),
      ParentAbsencesScreen(selectedChild: _selectedChild),
      ParentEventsScreen(
        selectedChild: _selectedChild,
        parentName: widget.parentName,
        onResponseChanged: () => _loadNotifications(),
      ),
      ParentMessagesScreen(
        parentEmail: widget.parentEmail,
        parentName: widget.parentName,
        selectedChild: _selectedChild,
      ),
      ParentProfileScreen(
        parentEmail: widget.parentEmail,
        parentName: widget.parentName,
      ),
    ];
    setState(() {});
  }

  void _navigateToPage(int index) {
    setState(() => _selectedIndex = index);
  }

  void _updateSelectedChild(ChildModel? child) {
    if (child != null && child != _selectedChild) {
      setState(() {
        _selectedChild = child;
        _selectedChildClass = child.className;
      });
      _loadNotifications();
      _initPages();
    }
  }

  void _showLinkChildDialog() {
    final List<TextEditingController> codeControllers = List.generate(10, (_) => TextEditingController());
    final List<FocusNode> focusNodes = List.generate(10, (_) => FocusNode());
    bool isLinking = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.add_circle, color: const Color(0xFF0288D1), size: 24),
                const SizedBox(width: 8),
                const Text('Lier un nouvel enfant'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Entrez le code à 10 chiffres de votre enfant:'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(10, (index) {
                    return SizedBox(
                      width: 45,
                      child: TextField(
                        controller: codeControllers[index],
                        focusNode: focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 9) {
                            FocusScope.of(dialogContext).requestFocus(focusNodes[index + 1]);
                          }
                          if (index == 9 && value.isNotEmpty) {
                            Future.delayed(const Duration(milliseconds: 100), () async {
                              String code = codeControllers.map((c) => c.text).join();
                              if (code.length == 10) {
                                setDialogState(() => isLinking = true);
                                final result = await ApiService.verifyParentCode(parentCode: code);
                                if (mounted) {
                                  setDialogState(() => isLinking = false);
                                  if (result['success']) {
                                    await _loadChildren();
                                    if (mounted) {
                                      Navigator.pop(dialogContext);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✅ Nouvel enfant lié avec succès'), backgroundColor: Colors.green),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result['message'] ?? 'Code invalide'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            });
                          }
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ANNULER')),
              ElevatedButton(
                onPressed: isLinking ? null : () async {
                  String code = codeControllers.map((c) => c.text).join();
                  if (code.length == 10) {
                    setDialogState(() => isLinking = true);
                    final result = await ApiService.verifyParentCode(parentCode: code);
                    if (mounted) {
                      setDialogState(() => isLinking = false);
                      if (result['success']) {
                        await _loadChildren();
                        if (mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Nouvel enfant lié avec succès'), backgroundColor: Colors.green),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Code invalide'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code incomplet (10 chiffres requis)'), backgroundColor: Colors.orange),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1)),
                child: isLinking
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('LIER'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChildSelector() {
    if (_children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun enfant lié. Cliquez sur + pour en ajouter.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (_children.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vous avez un seul enfant : ${_children[0].fullName}'), backgroundColor: Colors.blue),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  const Text('Changer d\'enfant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF01579B))),
                  const SizedBox(height: 8),
                  Text('Parent: ${widget.parentName}', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 20),
                  ..._children.map((child) {
                    final isCurrent = child.id == _selectedChild?.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0288D1).withOpacity(0.1),
                        child: Text(child.fullName.substring(0, 1).toUpperCase(), style: const TextStyle(color: Color(0xFF0288D1), fontWeight: FontWeight.bold)),
                      ),
                      title: Text(child.fullName, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? Colors.green : Colors.black87)),
                      subtitle: Text(child.className),
                      trailing: isCurrent ? const Chip(label: Text('Actuel'), backgroundColor: Colors.green, labelStyle: TextStyle(color: Colors.white, fontSize: 10)) : null,
                      onTap: () {
                        Navigator.pop(context);
                        if (child.id != _selectedChild?.id) {
                          _updateSelectedChild(child);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('👶 Enfant changé pour: ${child.fullName}'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.school, color: Color(0xFF0288D1), size: 20)),
                      const SizedBox(width: 8),
                      const Text('MySchool', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _isLoading ? null : _showChildSelector,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                          child: _isLoading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.family_restroom, size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(_selectedChild?.fullName ?? 'Aucun enfant', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                                    if (_children.length > 1) ...[const SizedBox(width: 4), Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.8), size: 18)],
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showLinkChildDialog,
                        child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.add, color: Colors.white, size: 18)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : _pages[_selectedIndex],
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_menuItems.length, (index) {
                final isSelected = _selectedIndex == index;
                return InkWell(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(_menuItems[index]['icon'], color: isSelected ? const Color(0xFF0288D1) : Colors.grey, size: 22),
                            if (index == 4 && _pendingEvents > 0)
                              Positioned(
                                right: -8, top: -8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(_pendingEvents > 9 ? '9+' : '$_pendingEvents', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_menuItems[index]['label'], style: TextStyle(fontSize: 10, color: isSelected ? const Color(0xFF0288D1) : Colors.grey)),
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

// Page d'accueil parent (sans "À FAIRE")
class ParentHomePage extends StatelessWidget {
  final String parentName;
  final int childrenCount;
  final String selectedChildName;
  final String selectedChildClass;
  final int pendingEvents;
  final VoidCallback onViewCourses;
  final VoidCallback onViewGrades;
  final VoidCallback onViewAbsences;
  final VoidCallback onViewEvents;
  final VoidCallback onViewMessages;

  const ParentHomePage({
    super.key,
    required this.parentName,
    required this.childrenCount,
    required this.selectedChildName,
    required this.selectedChildClass,
    required this.pendingEvents,
    required this.onViewCourses,
    required this.onViewGrades,
    required this.onViewAbsences,
    required this.onViewEvents,
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
            // Carte de bienvenue
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour,', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                  Text(parentName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(Icons.people, '$childrenCount', 'Enfants', Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(Icons.class_, selectedChildClass, 'Classe', Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Enfant sélectionné
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
                  const Text('👶 ENFANT SÉLECTIONNÉ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF01579B))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(color: const Color(0xFF0288D1).withOpacity(0.1), borderRadius: BorderRadius.circular(25)),
                        child: Center(child: Text(selectedChildName.isNotEmpty ? selectedChildName.substring(0, 1).toUpperCase() : '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0288D1)))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(selectedChildName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(selectedChildClass, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          ],
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
                      Expanded(child: _buildMenuItem(Icons.message, 'Messages', const Color(0xFF0288D1), onViewMessages)),
                      const SizedBox(width: 12),
                      Expanded(child: Container()),
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