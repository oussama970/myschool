// lib/screens/student/student_absences_screen.dart
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

class StudentAbsencesScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentClass;

  const StudentAbsencesScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentClass,
  });

  @override
  State<StudentAbsencesScreen> createState() => _StudentAbsencesScreenState();
}

class _StudentAbsencesScreenState extends State<StudentAbsencesScreen> {
  List<Map<String, dynamic>> _absences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAbsences();
  }

  Future<void> _loadAbsences() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getStudentAbsences(widget.studentId);
      
      print('📡 Résultat getStudentAbsences: ${result['success']}');
      print('📊 Nombre d\'absences: ${result['absences']?.length ?? 0}');
      
      if (mounted) {
        setState(() {
          _absences = List<Map<String, dynamic>>.from(result['absences'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'Date inconnue';
    try {
      DateTime date;
      if (dateString is DateTime) {
        date = dateString;
      } else {
        date = DateTime.parse(dateString.toString());
      }
      final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString.toString();
    }
  }

  String _getTimeRange(Map<String, dynamic> absence) {
    if (absence['time'] != null && absence['time'].toString().isNotEmpty) {
      String timeStr = absence['time'].toString();
      if (timeStr.contains(':')) {
        int hour = int.parse(timeStr.split(':')[0]);
        return '${hour}h-${hour + 1}h';
      }
      return timeStr;
    }
    return 'Horaire inconnu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Absences - ${widget.studentName}'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _absences.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune absence',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Félicitations !',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAbsences,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _absences.length,
                    itemBuilder: (context, index) {
                      final absence = _absences[index];
                      final absenceDate = _formatDate(absence['date']);
                      final timeRange = _getTimeRange(absence);
                      final subject = absence['subject'] ?? 'Non spécifié';
                      final reason = absence['reason'] ?? '';
                      final teacherName = absence['declaredBy'] ?? 'Enseignant';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0288D1).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.event_busy,
                                      color: Color(0xFF0288D1),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          absenceDate,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 12, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              timeRange,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Colors.grey),
                              _buildDetailRow(Icons.menu_book, 'Matière', subject),
                              const SizedBox(height: 8),
                              _buildDetailRow(Icons.person, 'Enseignant', teacherName),
                              if (reason.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildDetailRow(Icons.comment, 'Motif', reason),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF0288D1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF0288D1)),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 75,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}