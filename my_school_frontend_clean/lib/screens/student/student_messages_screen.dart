// lib/screens/student/student_messages_screen.dart
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'student_chat_screen.dart';

class StudentMessagesScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentClass;

  const StudentMessagesScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentClass,
  });

  @override
  State<StudentMessagesScreen> createState() => _StudentMessagesScreenState();
}

class _StudentMessagesScreenState extends State<StudentMessagesScreen> {
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  Map<String, int> _unreadCounts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadTeachers();
    await _loadConversations();
    setState(() => _isLoading = false);
  }

  Future<void> _loadTeachers() async {
    try {
      final result = await ApiService.getTeachers();
      if (result['success'] && mounted) {
        final List<dynamic> teachers = result['teachers'] ?? [];
        
        // Filtrer les enseignants qui enseignent dans la classe de l'élève
        final filtered = teachers.where((t) {
          // Vérification 1: assignedClasses (liste)
          final assignedClasses = t['assignedClasses'];
          if (assignedClasses != null && assignedClasses is List) {
            if (assignedClasses.contains(widget.studentClass)) {
              print('✅ Enseignant ${t['fullName']} trouvé via assignedClasses');
              return true;
            }
          }
          
          // Vérification 2: assignedClasses (string avec virgules)
          if (assignedClasses != null && assignedClasses is String && assignedClasses.isNotEmpty) {
            final classesList = assignedClasses.split(',').map((c) => c.trim()).toList();
            if (classesList.contains(widget.studentClass)) {
              print('✅ Enseignant ${t['fullName']} trouvé via assignedClasses (string)');
              return true;
            }
          }
          
          // Vérification 3: className (champ direct)
          final className = t['className'];
          if (className != null && className.toString() == widget.studentClass) {
            print('✅ Enseignant ${t['fullName']} trouvé via className');
            return true;
          }
          
          // Vérification 4: classes (autre nom de champ possible)
          final classes = t['classes'];
          if (classes != null && classes is List) {
            if (classes.contains(widget.studentClass)) {
              print('✅ Enseignant ${t['fullName']} trouvé via classes');
              return true;
            }
          }
          
          return false;
        }).toList();
        
        print('📚 Classe: ${widget.studentClass}');
        print('👨‍🏫 Total enseignants: ${teachers.length}');
        print('✅ Enseignants filtrés: ${filtered.length}');
        
        setState(() {
          _teachers = List<Map<String, dynamic>>.from(filtered);
        });
      }
    } catch (e) {
      print('❌ Erreur chargement enseignants: $e');
    }
  }

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

  String _getAvatar(String name) {
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Messages - ${widget.studentName}'),
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
                        'Pour la classe: ${widget.studentClass}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Rafraîchir'),
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
                                builder: (context) => StudentChatScreen(
                                  teacherId: teacher['_id'],
                                  teacherName: teacher['fullName'],
                                  teacherEmail: teacher['email'],
                                  studentId: widget.studentId,
                                  studentName: widget.studentName,
                                  studentClass: widget.studentClass,
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
                                      // Afficher la matière enseignée
                                      if (teacher['subjects'] != null && (teacher['subjects'] as List).isNotEmpty)
                                        Text(
                                          '📚 ${(teacher['subjects'] as List).join(', ')}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      // Afficher la classe
                                      Text(
                                        '🏫 Classe: ${widget.studentClass}',
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