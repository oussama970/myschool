import 'package:flutter/material.dart';
import 'teacher_chat_screen.dart';

class TeacherMessagesScreen extends StatefulWidget {
  final String teacherEmail;
  final String className;

  const TeacherMessagesScreen({
    super.key,
    required this.teacherEmail,
    required this.className,
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
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _parents = [
        {'name': 'Sophie Dupont', 'role': 'Parent de Chloé', 'lastMessage': 'Merci pour votre aide', 'time': 'Il y a 5 min', 'unread': true},
        {'name': 'Marc Martin', 'role': 'Parent de Léo, Paul', 'lastMessage': 'Bien reçu, merci', 'time': 'Il y a 2 heures', 'unread': false},
        {'name': 'Julie Bernard', 'role': 'Parent de Emma, Lucas', 'lastMessage': 'Je serai présent à la réunion', 'time': 'Hier', 'unread': false},
      ];
      _students = [
        {'name': 'Chloé Dupont', 'class': 'CE2 A', 'lastMessage': 'J\'ai fini l\'exercice !', 'time': 'Il y a 5 min', 'unread': true},
        {'name': 'Léo Martin', 'class': 'CM1 A', 'lastMessage': 'Je n\'ai pas compris l\'exercice 3', 'time': 'Il y a 1 heure', 'unread': false},
        {'name': 'Emma Bernard', 'class': 'CM1 B', 'lastMessage': 'Merci pour l\'aide !', 'time': 'Hier', 'unread': false},
      ];
      _teachers = [
        {'name': 'Pierre Martin', 'subject': 'CM2 B', 'lastMessage': 'Bonne idée pour la sortie !', 'time': 'En ligne', 'unread': false},
        {'name': 'Julie Bernard', 'subject': 'CM1 B', 'lastMessage': 'Le programme est prêt', 'time': 'Il y a 30 min', 'unread': false},
      ];
      _isLoading = false;
    });
  }

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

          // Onglets
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
              children: List.generate(_tabs.length, (index) {
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
                        color: _selectedTab == index
                            ? const Color(0xFF0288D1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _tabs[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTab == index
                              ? Colors.white
                              : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),

          // Contenu
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 0
                    ? _buildContactList(_parents)
                    : _selectedTab == 1
                        ? _buildStudentList(_students)
                        : _buildContactList(_teachers),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList(List<Map<String, dynamic>> contacts) {
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun message', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0288D1).withOpacity(0.1),
              child: const Icon(Icons.person, color: Color(0xFF0288D1)),
            ),
            title: Text(
              contact['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              contact['lastMessage'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  contact['time'],
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                if (contact['unread'] == true)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherChatScreen(
                    contactName: contact['name'],
                    contactRole: contact['role'] ?? contact['subject'] ?? contact['class'],
                    teacherEmail: widget.teacherEmail,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStudentList(List<Map<String, dynamic>> students) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF4CAF9F).withOpacity(0.1),
              child: const Icon(Icons.school, color: Color(0xFF4CAF9F)),
            ),
            title: Text(
              student['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              student['lastMessage'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  student['time'],
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                if (student['unread'] == true)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherChatScreen(
                    contactName: student['name'],
                    contactRole: student['class'],
                    teacherEmail: widget.teacherEmail,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}