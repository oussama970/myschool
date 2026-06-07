// lib/screens/teacher/teacher_messages_screen.dart
/// Écran enseignant pour la gestion des messages avec parents, élèves et autres enseignants
/// Affiche les conversations avec compteur de messages non lus et mise à jour en temps réel

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'teacher_chat_screen.dart';

class TeacherMessagesScreen extends StatefulWidget {
  final String teacherEmail;
  final String className;
  final String teacherId;
  final Function(int)? onUnreadCountChanged;

  const TeacherMessagesScreen({
    super.key,
    required this.teacherEmail,
    required this.className,
    required this.teacherId,
    this.onUnreadCountChanged,
  });

  @override
  State<TeacherMessagesScreen> createState() => _TeacherMessagesScreenState();
}

class _TeacherMessagesScreenState extends State<TeacherMessagesScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['👥 Parents', '🧑‍🎓 Élèves', '👨‍🏫 Enseignants'];
  
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _conversations = [];
  
  bool _isLoading = true;
  Timer? _pollingTimer;
  
  int _unreadParentsCount = 0;
  int _unreadStudentsCount = 0;
  int _unreadTeachersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTeachers();
    _loadConversations();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Démarre le polling pour mettre à jour les conversations toutes les 5 secondes
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadConversations();
      }
    });
  }

  /// Rafraîchit les conversations
  Future<void> _refreshConversations() async {
    await _loadConversations();
    if (mounted) {
      setState(() {});
    }
  }

  /// Charge les conversations depuis l'API
  Future<void> _loadConversations() async {
    if (!mounted) return;
    try {
      final result = await ApiService.getConversations();
      if (result['success'] && mounted) {
        final List<dynamic> conversations = result['conversations'] ?? [];
        final List<Map<String, dynamic>> tempList = [];
        int parentsCount = 0;
        int studentsCount = 0;
        int teachersCount = 0;
        
        for (var c in conversations) {
          // Sécurisation: récupérer unreadCount ou utiliser 0 par défaut
          int unread = 0;
          try {
            unread = c['unreadCount'] ?? 0;
          } catch (e) {
            unread = 0;
          }
          
          final role = c['role']?.toString() ?? '';
          
          tempList.add({
            'id': c['id']?.toString() ?? '',
            'name': c['name']?.toString() ?? 'Inconnu',
            'role': role,
            'lastMessage': c['lastMessage']?.toString() ?? '',
            'lastMessageTime': c['lastMessageTime'],
            'unreadCount': unread,
          });
          
          if (role == 'parent') {
            parentsCount += unread;
          } else if (role == 'student') {
            studentsCount += unread;
          } else if (role == 'teacher') {
            teachersCount += unread;
          }
        }
        
        if (mounted) {
          setState(() {
            _conversations = tempList;
            _unreadParentsCount = parentsCount;
            _unreadStudentsCount = studentsCount;
            _unreadTeachersCount = teachersCount;
          });
          
          if (widget.onUnreadCountChanged != null) {
            final totalUnread = parentsCount + studentsCount + teachersCount;
            widget.onUnreadCountChanged!(totalUnread);
          }
        }
      }
    } catch (e) {
      print('Erreur chargement conversations: $e');
    }
  }

  /// Récupère la première lettre du nom pour l'avatar
  String _getAvatar(dynamic fullName) {
    if (fullName == null) return '?';
    final String name = fullName.toString();
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  /// Charge les parents et élèves de la classe
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final studentsResult = await ApiService.getStudentsByClass(widget.className);
      
      List<String> studentEmails = [];
      
      if (studentsResult['success'] && mounted) {
        final List<dynamic> students = studentsResult['students'] ?? [];
        final List<Map<String, dynamic>> tempStudents = [];
        for (var s in students) {
          tempStudents.add({
            'id': s['_id']?.toString() ?? '',
            'name': s['fullName']?.toString() ?? 'Inconnu',
            'class': widget.className,
            'email': s['email']?.toString() ?? '',
            'avatar': _getAvatar(s['fullName']),
          });
          studentEmails.add(s['email']?.toString() ?? '');
        }
        setState(() {
          _students = tempStudents;
        });
      }
      
      final parentsResult = await ApiService.getParents();
      
      if (parentsResult['success'] && mounted) {
        final List<dynamic> allParents = parentsResult['parents'] ?? [];
        final List<Map<String, dynamic>> filteredParents = [];
        
        for (var parent in allParents) {
          final List<dynamic> children = parent['children'] ?? [];
          bool hasChildInClass = false;
          String childName = '';
          
          for (var child in children) {
            final String childEmail = child['email']?.toString() ?? '';
            final String childClassName = child['className']?.toString() ?? '';
            
            if (studentEmails.contains(childEmail) || childClassName == widget.className) {
              hasChildInClass = true;
              childName = child['fullName']?.toString() ?? '';
              break;
            }
          }
          
          if (hasChildInClass) {
            filteredParents.add({
              'id': parent['_id']?.toString() ?? '',
              'name': parent['fullName']?.toString() ?? 'Inconnu',
              'email': parent['email']?.toString() ?? '',
              'childName': childName,
              'role': 'parent',
              'avatar': _getAvatar(parent['fullName']),
            });
          }
        }
        
        if (mounted) {
          setState(() {
            _parents = filteredParents;
          });
        }
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur chargement données: $e');
      if (mounted) {
        _loadMockData();
        setState(() => _isLoading = false);
      }
    }
  }

  /// Charge la liste des enseignants
  Future<void> _loadTeachers() async {
    if (!mounted) return;
    try {
      final result = await ApiService.getTeachers();
      
      if (result['success'] && mounted) {
        final List<dynamic> teachers = result['teachers'] ?? [];
        final List<Map<String, dynamic>> tempTeachers = [];
        for (var t in teachers) {
          tempTeachers.add({
            'id': t['_id']?.toString() ?? '',
            'name': t['fullName']?.toString() ?? 'Inconnu',
            'email': t['email']?.toString() ?? '',
            'subjects': t['subjects'] ?? [],
            'role': 'teacher',
            'avatar': _getAvatar(t['fullName']),
          });
        }
        setState(() {
          _teachers = tempTeachers;
        });
      }
    } catch (e) {
      print('Erreur chargement enseignants: $e');
      if (mounted) {
        _loadMockTeachers();
      }
    }
  }

  /// Charge des données mockées en cas d'erreur (parents et élèves)
  void _loadMockData() {
    if (!mounted) return;
    setState(() {
      _students = [
        {'id': '1', 'name': 'Chloé Dupont', 'class': widget.className, 'email': 'chloe@test.com', 'avatar': 'C'},
        {'id': '2', 'name': 'Léo Martin', 'class': widget.className, 'email': 'leo@test.com', 'avatar': 'L'},
      ];
      
      _parents = [
        {'id': '3', 'name': 'Sophie Dupont', 'email': 'sophie@test.com', 'childName': 'Chloé Dupont', 'role': 'parent', 'avatar': 'S'},
        {'id': '4', 'name': 'Marc Martin', 'email': 'marc@test.com', 'childName': 'Léo Martin', 'role': 'parent', 'avatar': 'M'},
      ];
    });
  }

  /// Charge des données mockées pour les enseignants
  void _loadMockTeachers() {
    if (!mounted) return;
    setState(() {
      _teachers = [
        {'id': '5', 'name': 'Mme Martin', 'email': 'martin@school.com', 'subjects': ['Maths'], 'role': 'teacher', 'avatar': 'M'},
        {'id': '6', 'name': 'M. Dubois', 'email': 'dubois@school.com', 'subjects': ['Français'], 'role': 'teacher', 'avatar': 'D'},
      ];
    });
  }

  /// Récupère le nombre de messages non lus pour un contact
  int _getUnreadCount(String contactId) {
    if (contactId.isEmpty) return 0;
    try {
      for (var conv in _conversations) {
        if (conv['id'] == contactId) {
          return conv['unreadCount'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Récupère le dernier message d'une conversation
  String _getLastMessage(String contactId) {
    if (contactId.isEmpty) return '';
    try {
      for (var conv in _conversations) {
        if (conv['id'] == contactId) {
          final msg = conv['lastMessage'];
          return msg ?? '';
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Récupère l'heure du dernier message formatée
  String _getLastMessageTime(String contactId) {
    if (contactId.isEmpty) return '';
    try {
      for (var conv in _conversations) {
        if (conv['id'] == contactId) {
          final time = conv['lastMessageTime'];
          if (time == null) return '';
          if (time is DateTime) {
            return _formatTime(time);
          }
          if (time is String) {
            try {
              return _formatTime(DateTime.parse(time));
            } catch (e) {
              return '';
            }
          }
          return '';
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Formate l'heure relative (ex: 2j, 5h, 10min, maintenant)
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}min';
    } else {
      return 'maintenant';
    }
  }

  /// Construit un onglet personnalisé avec badge de notification
  Widget _buildTabWithBadge(int index, String label, int badgeCount) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0288D1) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: 5,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
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
        ),
      ),
    );
  }

  /// Construit l'interface principale
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // En-tête
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '💬 MESSAGERIE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF01579B),
              ),
            ),
          ),

          // Barre d'onglets avec badges
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTabWithBadge(0, '👥 Parents', _unreadParentsCount),
                _buildTabWithBadge(1, '🧑‍🎓 Élèves', _unreadStudentsCount),
                _buildTabWithBadge(2, '👨‍🏫 Enseignants', _unreadTeachersCount),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Liste selon l'onglet sélectionné
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 0
                    ? _buildParentList()
                    : _selectedTab == 1
                        ? _buildStudentList()
                        : _buildTeacherList(),
          ),
        ],
      ),
    );
  }

  /// Construit la liste des parents
  Widget _buildParentList() {
    if (_parents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun parent lié aux élèves de cette classe',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
        await _loadConversations();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _parents.length,
        itemBuilder: (context, index) {
          final parent = _parents[index];
          final unreadCount = _getUnreadCount(parent['id']);
          final lastMessage = _getLastMessage(parent['id']);
          final lastTime = _getLastMessageTime(parent['id']);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherChatScreen(
                      contactId: parent['id'],
                      contactName: parent['name'],
                      contactRole: 'parent',
                      teacherId: widget.teacherId,
                      teacherName: widget.teacherEmail,
                      onMessagesRead: _refreshConversations,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFF0288D1).withOpacity(0.1),
                          child: Text(
                            parent['avatar'],
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  parent['name'],
                                  style: TextStyle(
                                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (lastTime.isNotEmpty)
                                Text(
                                  lastTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lastMessage.isNotEmpty ? lastMessage : 'Aucun message',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                                    fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (parent['childName'] != null && parent['childName'].isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    parent['childName'],
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construit la liste des élèves
  Widget _buildStudentList() {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun élève dans cette classe', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
        await _loadConversations();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          final unreadCount = _getUnreadCount(student['id']);
          final lastMessage = _getLastMessage(student['id']);
          final lastTime = _getLastMessageTime(student['id']);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherChatScreen(
                      contactId: student['id'],
                      contactName: student['name'],
                      contactRole: 'student',
                      teacherId: widget.teacherId,
                      teacherName: widget.teacherEmail,
                      onMessagesRead: _refreshConversations,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFF4CAF9F).withOpacity(0.1),
                          child: Text(
                            student['avatar'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF9F),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  student['name'],
                                  style: TextStyle(
                                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (lastTime.isNotEmpty)
                                Text(
                                  lastTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastMessage.isNotEmpty ? lastMessage : student['class'],
                            style: TextStyle(
                              fontSize: 13,
                              color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construit la liste des enseignants
  Widget _buildTeacherList() {
    if (_teachers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun enseignant', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadTeachers();
        await _loadConversations();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _teachers.length,
        itemBuilder: (context, index) {
          final teacher = _teachers[index];
          // Ne pas afficher l'enseignant lui-même
          if (teacher['email'] == widget.teacherEmail) {
            return const SizedBox.shrink();
          }
          final unreadCount = _getUnreadCount(teacher['id']);
          final lastMessage = _getLastMessage(teacher['id']);
          final lastTime = _getLastMessageTime(teacher['id']);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherChatScreen(
                      contactId: teacher['id'],
                      contactName: teacher['name'],
                      contactRole: 'teacher',
                      teacherId: widget.teacherId,
                      teacherName: widget.teacherEmail,
                      onMessagesRead: _refreshConversations,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
                          child: Text(
                            teacher['avatar'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF9800),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  teacher['name'],
                                  style: TextStyle(
                                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (lastTime.isNotEmpty)
                                Text(
                                  lastTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastMessage.isNotEmpty ? lastMessage : (teacher['subjects'].isNotEmpty ? teacher['subjects'].join(', ') : 'Enseignant'),
                            style: TextStyle(
                              fontSize: 13,
                              color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}