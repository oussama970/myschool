// lib/screens/teacher/teacher_event_details_screen.dart
/// Écran enseignant pour visualiser les détails d'un événement et les réponses des parents
/// Affiche les statistiques de participation (acceptés, refusés, en attente) et la liste des élèves

import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/models/event_model.dart';

class TeacherEventDetailsScreen extends StatefulWidget {
  final EventModel event;
  final String className;
  final String teacherId;
  final String teacherName;

  const TeacherEventDetailsScreen({
    super.key,
    required this.event,
    required this.className,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<TeacherEventDetailsScreen> createState() => _TeacherEventDetailsScreenState();
}

class _TeacherEventDetailsScreenState extends State<TeacherEventDetailsScreen> {
  List<Map<String, dynamic>> _students = [];
  List<EventResponse> _responses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Charge les élèves de la classe et leurs réponses à l'événement
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final studentsResult = await ApiService.getStudentsByClass(widget.className);
      if (studentsResult['success']) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(studentsResult['students'] ?? []);
          _responses = List.from(widget.event.studentResponses);
        });
      }
    } catch (e) {
      print('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Récupère la réponse d'un élève spécifique
  EventResponse? _getStudentResponse(String studentId) {
    try {
      return _responses.firstWhere(
        (r) => r.studentId == studentId,
        orElse: () => EventResponse(
          studentId: studentId,
          studentName: '',
          response: 'pending',
          respondedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Retourne la couleur associée au statut de réponse
  Color _getStatusColor(String response) {
    switch (response) {
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  /// Retourne le texte associé au statut de réponse
  String _getStatusText(String response) {
    switch (response) {
      case 'accepted': return 'Accepté';
      case 'rejected': return 'Refusé';
      default: return 'En attente';
    }
  }

  /// Retourne l'icône associée au statut de réponse
  IconData _getStatusIcon(String response) {
    switch (response) {
      case 'accepted': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      default: return Icons.pending;
    }
  }

  /// Construit l'interface principale
  @override
  Widget build(BuildContext context) {
    final acceptedCount = _responses.where((r) => r.response == 'accepted').length;
    final rejectedCount = _responses.where((r) => r.response == 'rejected').length;
    final pendingCount = _students.length - acceptedCount - rejectedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.event.title),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Carte des informations de l'événement
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📋 INFORMATIONS',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Titre', widget.event.title),
                        _buildInfoRow('Description', widget.event.description),
                        _buildInfoRow('Date', '${widget.event.date.day}/${widget.event.date.month}/${widget.event.date.year}'),
                        _buildInfoRow('Classe', widget.className),
                      ],
                    ),
                  ),
                  
                  // Cartes statistiques (nombre d'élèves, acceptés, refusés, en attente)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        _buildStatCard('${_students.length}', 'Élèves', Colors.blue),
                        _buildStatCard('$acceptedCount', 'Acceptés', Colors.green),
                        _buildStatCard('$rejectedCount', 'Refusés', Colors.red),
                        _buildStatCard('$pendingCount', 'Attente', Colors.orange),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Liste des réponses des élèves
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RÉPONSES PARENTS',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
                        ),
                        const SizedBox(height: 16),
                        if (_students.isEmpty)
                          const Center(child: Text('Aucun élève'))
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _students.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              final studentId = student['_id'].toString();
                              final response = _getStudentResponse(studentId);
                              final responseStatus = response?.response ?? 'pending';
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF0288D1).withOpacity(0.1),
                                  child: Text(
                                    student['fullName']?.substring(0, 1).toUpperCase() ?? '?',
                                    style: const TextStyle(color: Color(0xFF0288D1)),
                                  ),
                                ),
                                title: Text(student['fullName'] ?? 'Inconnu'),
                                subtitle: Text(student['email'] ?? ''),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(responseStatus).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(responseStatus),
                                    style: TextStyle(fontSize: 11, color: _getStatusColor(responseStatus)),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Construit une ligne d'information avec label et valeur
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  /// Construit une carte statistique (valeur + label)
  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}