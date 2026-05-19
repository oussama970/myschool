// lib/screens/parent/parent_absences_screen.dart
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/models/child_model.dart';

class ParentAbsencesScreen extends StatefulWidget {
  final ChildModel? selectedChild;

  const ParentAbsencesScreen({super.key, this.selectedChild});

  @override
  State<ParentAbsencesScreen> createState() => _ParentAbsencesScreenState();
}

class _ParentAbsencesScreenState extends State<ParentAbsencesScreen> {
  List<Map<String, dynamic>> _absences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAbsences();
  }

  @override
  void didUpdateWidget(ParentAbsencesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChild?.id != widget.selectedChild?.id) {
      _loadAbsences();
    }
  }

  Future<void> _loadAbsences() async {
    if (widget.selectedChild == null) {
      setState(() {
        _absences = [];
        _isLoading = false;
      });
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getStudentAbsencesForParent(widget.selectedChild!.id);
      
      print('📡 Réponse API: success=${result['success']}');
      
      if (mounted) {
        final absencesList = result['absences'] ?? [];
        print('📊 ${absencesList.length} absences reçues');
        
        setState(() {
          _absences = List<Map<String, dynamic>>.from(absencesList);
          _isLoading = false;
        });
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
        date = dateString.toLocal();
      } else {
        date = DateTime.parse(dateString.toString()).toLocal();
      }
      final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString.toString();
    }
  }

  String _getTimeRange(Map<String, dynamic> absence) {
    // Utiliser le champ 'time' de la base de données (format "08:00")
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

  String _getTeacherName(Map<String, dynamic> absence) {
    // Utiliser le champ 'declaredBy' de la base de données
    if (absence['declaredBy'] != null && absence['declaredBy'].toString().isNotEmpty) {
      return absence['declaredBy'].toString();
    }
    return 'Non spécifié';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedChild == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Absences'),
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
        title: Text('Absences - ${widget.selectedChild!.fullName}'),
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
                        'Pour ${widget.selectedChild!.fullName}',
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
                      final teacherName = _getTeacherName(absence);
                      
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
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 12,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                timeRange,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.orange[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              const Divider(color: Colors.grey),
                              
                              Column(
                                children: [
                                  _buildDetailRow(Icons.menu_book, 'Matière', subject),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(Icons.person, 'Enseignant', teacherName),
                                  if (reason.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _buildDetailRow(Icons.comment, 'Motif', reason),
                                  ],
                                ],
                              ),
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
          width: 80,
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