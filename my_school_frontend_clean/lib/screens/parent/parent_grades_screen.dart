// lib/screens/parent/parent_grades_screen.dart
/// Écran parent permettant de consulter les notes et examens des enfants
/// Affiche trois onglets (Oral, Evaluation, Examen) avec les notes obtenues,
/// les appréciations des enseignants et les photos de copies disponibles

import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/models/child_model.dart';

class ParentGradesScreen extends StatefulWidget {
  final ChildModel? selectedChild;

  const ParentGradesScreen({super.key, this.selectedChild});

  @override
  State<ParentGradesScreen> createState() => _ParentGradesScreenState();
}

class _ParentGradesScreenState extends State<ParentGradesScreen> {
  List<Map<String, dynamic>> _oralExams = [];
  List<Map<String, dynamic>> _evaluationExams = [];
  List<Map<String, dynamic>> _examExams = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  final List<String> _tabs = ['🎤 Oral', '📝 Evaluation', '📚 Examen'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Recharge les données si l'enfant sélectionné change
  @override
  void didUpdateWidget(ParentGradesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChild?.id != widget.selectedChild?.id) {
      _loadData();
    }
  }

  /// Charge les examens depuis l'API et les trie par type (Oral, Evaluation, Examen) et par date décroissante
  Future<void> _loadData() async {
    if (widget.selectedChild == null) {
      setState(() {
        _oralExams = [];
        _evaluationExams = [];
        _examExams = [];
        _isLoading = false;
      });
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      print('📊 Chargement des examens pour: ${widget.selectedChild!.fullName}');
      
      final examsResult = await ApiService.getAllExamsByClass(
        widget.selectedChild!.className,
        widget.selectedChild!.id
      );
      
      List<Map<String, dynamic>> oralList = [];
      List<Map<String, dynamic>> evaluationList = [];
      List<Map<String, dynamic>> examList = [];
      
      if (examsResult['success']) {
        final List<dynamic> exams = examsResult['events'] ?? [];
        
        print('📊 ${exams.length} examens trouvés');
        
        for (var exam in exams) {
          final hasGrade = exam['hasGrade'] == true;
          final gradeValue = exam['grade'];
          
          final examData = {
            'id': exam['_id'],
            'type': exam['type'] ?? 'Examen',
            'subject': exam['subject'] ?? 'Matière',
            'date': _formatDate(exam['date']),
            'dateTime': exam['date'],
            'dayName': _getDayName(exam['day'] ?? 'Lu'),
            'timeSlot': exam['timeSlot'] ?? '08h-09h',
            'description': exam['description'] ?? '',
            'hasGrade': hasGrade,
            'grade': gradeValue,
            'appreciation': exam['appreciation'] ?? '',
            'photoUrl': exam['photoUrl'] ?? '',
            'teacherName': exam['gradeTeacherName'] ?? exam['teacherName'] ?? '',
          };
          
          switch(examData['type']) {
            case 'Orale':
              oralList.add(examData);
              break;
            case 'Evaluation':
              evaluationList.add(examData);
              break;
            case 'Examen':
              examList.add(examData);
              break;
            default:
              examList.add(examData);
          }
        }
      }
      
      oralList.sort((a, b) => b['dateTime'].compareTo(a['dateTime']));
      evaluationList.sort((a, b) => b['dateTime'].compareTo(a['dateTime']));
      examList.sort((a, b) => b['dateTime'].compareTo(a['dateTime']));
      
      setState(() {
        _oralExams = oralList;
        _evaluationExams = evaluationList;
        _examExams = examList;
        _isLoading = false;
      });
      
      print('✅ Oral: ${_oralExams.length}, Evaluation: ${_evaluationExams.length}, Examen: ${_examExams.length}');
    } catch (e) {
      print('❌ Erreur: $e');
      setState(() {
        _oralExams = [];
        _evaluationExams = [];
        _examExams = [];
        _isLoading = false;
      });
    }
  }

  /// Convertit l'abréviation du jour en nom complet (Lu -> Lundi, Ma -> Mardi, etc.)
  String _getDayName(String day) {
    switch(day) {
      case 'Lu': return 'Lundi';
      case 'Ma': return 'Mardi';
      case 'Me': return 'Mercredi';
      case 'Je': return 'Jeudi';
      case 'Ve': return 'Vendredi';
      case 'Sa': return 'Samedi';
      default: return day;
    }
  }

  /// Formate une date au format français "JJ Mois AAAA"
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

  /// Retourne la couleur associée au type d'examen (Oral: violet, Evaluation: vert, Examen: rouge)
  Color _getExamTypeColor(String type) {
    switch(type) {
      case 'Orale': return Colors.deepPurple;
      case 'Evaluation': return Colors.teal;
      case 'Examen': return Colors.red;
      default: return const Color(0xFF0288D1);
    }
  }

  /// Retourne l'emoji associé au type d'examen
  String _getExamTypeIcon(String type) {
    switch(type) {
      case 'Orale': return '🎤';
      case 'Evaluation': return '📝';
      case 'Examen': return '📚';
      default: return '📋';
    }
  }

  /// Détermine la couleur de la note selon sa valeur (vert >16, bleu >12, orange >10, rouge <10)
  Color _getGradeColor(dynamic grade) {
    double gradeValue;
    if (grade == null) {
      gradeValue = 0;
    } else if (grade is int) {
      gradeValue = grade.toDouble();
    } else if (grade is double) {
      gradeValue = grade;
    } else {
      gradeValue = 0;
    }
    
    if (gradeValue >= 16) return Colors.green;
    if (gradeValue >= 12) return const Color(0xFF0288D1);
    if (gradeValue >= 10) return Colors.orange;
    return Colors.red;
  }

  /// Retourne l'appréciation textuelle selon la valeur de la note
  String _getGradeText(dynamic grade) {
    double gradeValue;
    if (grade == null) {
      return 'Non noté';
    } else if (grade is int) {
      gradeValue = grade.toDouble();
    } else {
      gradeValue = grade;
    }
    
    if (gradeValue >= 16) return 'Excellent !';
    if (gradeValue >= 14) return 'Très bien';
    if (gradeValue >= 12) return 'Bien';
    if (gradeValue >= 10) return 'Passable';
    if (gradeValue >= 8) return 'Insuffisant';
    return 'À améliorer';
  }

  /// Affiche une modale avec tous les détails d'un examen (note, appréciation, photo, etc.)
  void _showExamDetails(Map<String, dynamic> exam) {
    final bool hasGrade = exam['hasGrade'] == true;
    final dynamic gradeValue = exam['grade'];
    final String appreciation = exam['appreciation'] ?? '';
    final String photoUrl = exam['photoUrl'] ?? '';
    final String teacherName = exam['teacherName'] ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getExamTypeColor(exam['type']),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        _getExamTypeIcon(exam['type']),
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam['type'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exam['subject'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoChip(Icons.calendar_today, exam['date']),
                        _buildInfoChip(Icons.access_time, exam['timeSlot']),
                        _buildInfoChip(Icons.weekend, exam['dayName']),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  if (hasGrade) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getGradeColor(gradeValue).withOpacity(0.1),
                            _getGradeColor(gradeValue).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getGradeColor(gradeValue).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'NOTE OBTENUE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                gradeValue is int 
                                    ? gradeValue.toString() 
                                    : (gradeValue ?? 0).toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: _getGradeColor(gradeValue),
                                ),
                              ),
                              const Text(
                                '/20',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getGradeColor(gradeValue).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getGradeText(gradeValue),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getGradeColor(gradeValue),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (teacherName.isNotEmpty)
                      _buildDetailSection(
                        icon: Icons.person,
                        title: 'ENSEIGNANT',
                        content: teacherName,
                      ),
                    
                    if (appreciation.isNotEmpty)
                      _buildDetailSection(
                        icon: Icons.comment,
                        title: 'APPRÉCIATION',
                        content: appreciation,
                      ),
                    
                    if (photoUrl.isNotEmpty)
                      _buildPhotoSection(photoUrl),
                      
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pending,
                              size: 30,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Note non encore disponible',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'La note sera affichée une fois l\'évaluation corrigée par l\'enseignant.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  if (exam['description'].isNotEmpty)
                    _buildDetailSection(
                      icon: Icons.description,
                      title: 'DESCRIPTION',
                      content: exam['description'],
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un widget d'information avec icône et texte (pour date, heure, jour)
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF0288D1)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Construit une section de détails avec icône, titre et contenu
  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0288D1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF0288D1)),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une section d'affichage de photo avec aperçu cliquable
  Widget _buildPhotoSection(String photoUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0288D1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo, size: 16, color: Color(0xFF0288D1)),
              ),
              const SizedBox(width: 8),
              const Text(
                'PHOTO DE LA COPIE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showPhotoDialog(photoUrl),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image, size: 24, color: Color(0xFF0288D1)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Afficher la photo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Cliquez pour voir la copie de l\'élève',
                          style: TextStyle(
                            fontSize: 11,
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
        ],
      ),
    );
  }

  /// Affiche un dialogue avec la photo de la copie en grand format
  void _showPhotoDialog(String photoUrl) {
    String cleanUrl = photoUrl.replaceAll('\\', '/');
    final fileName = cleanUrl.split('/').last;
    final fullUrl = 'http://10.0.2.2:5000/uploads/$fileName';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0288D1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo, color: Colors.white),
                  const SizedBox(width: 10),
                  const Text('Photo de la copie', style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              width: MediaQuery.of(context).size.width * 0.9,
              child: Image.network(
                fullUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text('Chargement...', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text(
                          'Image non disponible',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          fileName,
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Retourne la liste des examens selon l'onglet sélectionné
  List<Map<String, dynamic>> _getCurrentExams() {
    switch(_selectedTab) {
      case 0: return _oralExams;
      case 1: return _evaluationExams;
      case 2: return _examExams;
      default: return [];
    }
  }

  /// Retourne le type d'examen selon l'onglet sélectionné
  String _getCurrentType() {
    switch(_selectedTab) {
      case 0: return 'Orale';
      case 1: return "Evaluation";
      case 2: return 'Examen';
      default: return '';
    }
  }

  /// Construit l'interface principale avec les onglets et la liste des examens
  @override
  Widget build(BuildContext context) {
    final currentExams = _getCurrentExams();
    final currentType = _getCurrentType();

    if (widget.selectedChild == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Examens'),
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
        title: Text('Examens - ${widget.selectedChild!.fullName}'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      final isSelected = _selectedTab == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0288D1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              _tabs[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                
                Expanded(
                  child: currentExams.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedTab == 0 ? Icons.mic : (_selectedTab == 1 ? Icons.assignment : Icons.science),
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun $currentType',
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
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: currentExams.length,
                            itemBuilder: (context, index) {
                              final exam = currentExams[index];
                              final hasGrade = exam['hasGrade'] == true;
                              final dynamic gradeValue = exam['grade'];
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  onTap: () => _showExamDetails(exam),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: _getExamTypeColor(exam['type']).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _getExamTypeIcon(exam['type']),
                                              style: const TextStyle(fontSize: 28),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                exam['subject'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    exam['date'],
                                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(Icons.access_time, size: 12, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    exam['timeSlot'],
                                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        if (hasGrade)
                                          Container(
                                            width: 45,
                                            height: 45,
                                            decoration: BoxDecoration(
                                              color: _getGradeColor(gradeValue).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                gradeValue is int ? gradeValue.toString() : (gradeValue ?? 0).toStringAsFixed(1),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getGradeColor(gradeValue),
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.pending, size: 14, color: Colors.orange),
                                                SizedBox(width: 4),
                                                Text(
                                                  'En attente',
                                                  style: TextStyle(fontSize: 10, color: Colors.orange),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}