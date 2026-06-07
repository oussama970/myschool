// lib/screens/parent/parent_messages_screen.dart
/// Écran parent permettant de consulter et d'envoyer des messages aux enseignants
/// Affiche la liste des enseignants de la classe de l'enfant avec les messages non lus

import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/models/child_model.dart';
import 'parent_chat_screen.dart';

class ParentMessagesScreen extends StatefulWidget {
  final String parentEmail;
  final String parentName;
  final ChildModel? selectedChild;

  const ParentMessagesScreen({
    super.key,
    required this.parentEmail,
    required this.parentName,
    this.selectedChild,
  });

  @override
  State<ParentMessagesScreen> createState() => _ParentMessagesScreenState();
}

class _ParentMessagesScreenState extends State<ParentMessagesScreen> {
  ChildModel? _selectedChild;
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  Map<String, int> _unreadCounts = {};

  @override
  void initState() {
    super.initState();
    _selectedChild = widget.selectedChild;
    _loadData();
  }

  /// Met à jour l'enfant sélectionné et recharge les données si nécessaire
  @override
  void didUpdateWidget(ParentMessagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChild?.id != widget.selectedChild?.id) {
      setState(() {
        _selectedChild = widget.selectedChild;
      });
      _loadData();
    }
  }

  /// Charge tous les enseignants et les conversations existantes
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadTeachers();
    await _loadConversations();
    setState(() => _isLoading = false);
  }

  /// Récupère la liste des enseignants depuis l'API et filtre par classe de l'enfant
  Future<void> _loadTeachers() async {
    try {
      final result = await ApiService.getTeachers();
      if (result['success'] && mounted) {
        final List<dynamic> teachers = result['teachers'] ?? [];
        
        if (_selectedChild != null) {
          final filtered = teachers.where((t) {
            final classes = t['assignedClasses'] ?? [];
            return classes.contains(_selectedChild!.className);
          }).toList();
          setState(() {
            _teachers = List<Map<String, dynamic>>.from(filtered);
          });
        } else {
          setState(() {
            _teachers = List<Map<String, dynamic>>.from(teachers);
          });
        }
      }
    } catch (e) {
      print('Erreur chargement enseignants: $e');
    }
  }

  /// Récupère les conversations existantes et le nombre de messages non lus
  Future<void> _loadConversations() async {
    try {
      final result = await ApiService.getConversations();
      if (result['success'] && mounted) {
        final List<dynamic> conversations = result['conversations'] ?? [];
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(conversations);
          _unreadCounts.clear();
          for (var conv in _conversations) {
            _unreadCounts[conv['id']] = conv['unreadCount'] ?? 0;
          }
        });
      }
    } catch (e) {
      print('Erreur chargement conversations: $e');
    }
  }

  /// Récupère la première lettre du nom pour l'avatar
  String _getAvatar(String name) {
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  /// Construit l'interface principale avec la liste des enseignants
  @override
  Widget build(BuildContext context) {
    if (_selectedChild == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: const Color(0xFF0288D1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.child_care, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Aucun enfant sélectionné',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Messages - ${_selectedChild!.fullName}'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teachers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun enseignant disponible',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pour la classe: ${_selectedChild!.className}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = _teachers[index];
                      final unreadCount = _unreadCounts[teacher['_id']] ?? 0;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ParentChatScreen(
                                  teacherId: teacher['_id'],
                                  teacherName: teacher['fullName'],
                                  teacherEmail: teacher['email'],
                                  parentId: widget.parentEmail,
                                  parentName: widget.parentName,
                                  childName: _selectedChild!.fullName,
                                  className: _selectedChild!.className,
                                  onMessagesRead: _loadConversations,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundColor: const Color(0xFF0288D1).withOpacity(0.1),
                                      child: Text(
                                        _getAvatar(teacher['fullName'] ?? '?'),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0288D1),
                                        ),
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
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
                                            unreadCount > 9 ? '9+' : '$unreadCount',
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
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        teacher['fullName'] ?? 'Enseignant',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Matière: ${(teacher['subjects'] as List?)?.join(', ') ?? '-'}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      Text(
                                        _selectedChild!.className,
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 22,
                                      minHeight: 22,
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}