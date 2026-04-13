import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'teacher_student_detail_screen.dart';

class TeacherClassScreen extends StatefulWidget {
  final String teacherEmail;
  final String className;

  const TeacherClassScreen({
    super.key,
    required this.teacherEmail,
    required this.className,
  });

  @override
  State<TeacherClassScreen> createState() => _TeacherClassScreenState();
}

class _TeacherClassScreenState extends State<TeacherClassScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    
    try {
      print('========== CHARGEMENT ÉLÈVES ==========');
      print('Classe: ${widget.className}');
      
      final result = await ApiService.getStudentsByClass(widget.className);
      
      print('Réponse API - success: ${result['success']}');
      print('Réponse API - students: ${result['students']}');
      
      if (result['success']) {
        final students = result['students'] ?? [];
        print('✅ ${students.length} élèves trouvés');
        
        for (var student in students) {
          print('   - ${student['fullName']} (${student['email']}) - Classe: ${student['className']}');
        }
        
        setState(() {
          _students = students;
        });
      } else {
        print('❌ Erreur: ${result['message']}');
        setState(() {
          _students = [];
        });
      }
    } catch (e) {
      print('🔥 Exception: $e');
      setState(() {
        _students = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getFilteredStudents() {
    if (_searchController.text.isEmpty) return _students;
    return _students.where((s) =>
      s['fullName'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
      s['email'].toString().toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _loadStudents,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '👥 Mes élèves (${_students.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF01579B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0288D1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Color(0xFF0288D1),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '🔍 Rechercher un élève',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF0288D1)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun élève dans cette classe',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Les élèves sont ajoutés par l\'administrateur',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _getFilteredStudents().length,
                          itemBuilder: (context, index) {
                            final student = _getFilteredStudents()[index];
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
                                      builder: (context) => TeacherStudentDetailScreen(
                                        student: student,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFF0288D1).withOpacity(0.1),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF0288D1),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student['fullName'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              student['email'] ?? '',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'Parent: ${student['parentEmail'] ?? '-'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}