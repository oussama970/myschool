import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

class TeacherStudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final String teacherId;
  final String teacherName;
  final String teacherSubject;
  final String teacherEmail;
  final String className;

  const TeacherStudentDetailScreen({
    super.key,
    required this.student,
    required this.teacherId,
    required this.teacherName,
    required this.teacherSubject,
    required this.teacherEmail,
    required this.className,
  });

  @override
  State<TeacherStudentDetailScreen> createState() => _TeacherStudentDetailScreenState();
}

class _TeacherStudentDetailScreenState extends State<TeacherStudentDetailScreen> {
  bool _isLoading = true;
  List<String> _linkedParents = [];
  bool _hasParents = false;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    
    try {
      final studentId = widget.student['_id'] ?? widget.student['id'];
      
      // Récupérer les parents liés à l'élève
      final result = await ApiService.getStudentLinkedParents(studentId);
      
      if (result['success'] && mounted) {
        setState(() {
          _linkedParents = List<String>.from(result['parents'] ?? []);
          _hasParents = _linkedParents.isNotEmpty;
        });
      }
    } catch (e) {
      print('Erreur chargement données: $e');
      setState(() {
        _linkedParents = [];
        _hasParents = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('👤 ${widget.student['fullName'] ?? 'Élève'}'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStudentData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildParentsCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 INFORMATIONS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF01579B))),
          const SizedBox(height: 16),
          _buildInfoRow('Nom', widget.student['fullName'] ?? '-'),
          _buildInfoRow('Email', widget.student['email'] ?? '-'),
          _buildInfoRow('Classe', widget.className),
        ],
      ),
    );
  }

  Widget _buildParentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF9F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.family_restroom, color: Color(0xFF4CAF9F), size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                '👪 PARENTS LIÉS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_hasParents)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucun parent lié à cet élève',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _linkedParents.map((parentEmail) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF9F).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF9F).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF9F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person, color: Color(0xFF4CAF9F), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email du parent',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            parentEmail,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF01579B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Lié',
                        style: TextStyle(fontSize: 10, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}