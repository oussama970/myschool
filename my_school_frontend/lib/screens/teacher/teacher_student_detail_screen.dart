import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

class TeacherStudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const TeacherStudentDetailScreen({
    super.key,
    required this.student,
  });

  @override
  State<TeacherStudentDetailScreen> createState() => _TeacherStudentDetailScreenState();
}

class _TeacherStudentDetailScreenState extends State<TeacherStudentDetailScreen> {
  final _gradeController = TextEditingController();
  final _appreciationController = TextEditingController();
  final _absenceReasonController = TextEditingController();
  String _selectedSubject = 'Maths';
  double _selectedGrade = 10;
  bool _isAddingGrade = false;
  bool _isAddingAbsence = false;
  bool _absenceJustified = false;
  
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _absences = [];
  bool _isLoading = true;

  final List<String> _subjects = [
    'Maths', 'Français', 'Histoire', 'Sciences', 
    'Anglais', 'EPS', 'Arts', 'Musique'
  ];

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _appreciationController.dispose();
    _absenceReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    
    // Simuler le chargement des données
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _grades = [
        {'subject': 'Maths', 'grade': 16, 'appreciation': 'Très bien', 'date': '10/03/2024', 'teacher': 'Mme Martin'},
        {'subject': 'Français', 'grade': 14, 'appreciation': 'Bien', 'date': '05/03/2024', 'teacher': 'Mme Martin'},
        {'subject': 'Histoire', 'grade': 18, 'appreciation': 'Excellent', 'date': '28/02/2024', 'teacher': 'M. Dubois'},
        {'subject': 'Sciences', 'grade': 15, 'appreciation': 'Bien', 'date': '20/02/2024', 'teacher': 'Mme Martin'},
      ];
      
      _absences = [
        {'date': '10/03/2024', 'justified': true, 'reason': 'Maladie', 'declaredBy': 'Mme Martin'},
        {'date': '05/02/2024', 'justified': true, 'reason': 'Rendez-vous médical', 'declaredBy': 'Parent'},
        {'date': '15/01/2024', 'justified': false, 'reason': 'Retard', 'declaredBy': 'Mme Martin'},
      ];
      
      _isLoading = false;
    });
  }

  Future<void> _addGrade() async {
    if (_gradeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une note'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _isAddingGrade = true);
    
    final result = await ApiService.addGrade(
      studentId: widget.student['_id'],
      subject: _selectedSubject,
      grade: _selectedGrade,
      appreciation: _appreciationController.text,
    );
    
    setState(() => _isAddingGrade = false);
    
    if (result['success']) {
      setState(() {
        _grades.insert(0, {
          'subject': _selectedSubject,
          'grade': _selectedGrade,
          'appreciation': _appreciationController.text.isEmpty ? 'Sans appréciation' : _appreciationController.text,
          'date': _getCurrentDate(),
          'teacher': 'Mme Martin',
        });
      });
      
      _gradeController.clear();
      _appreciationController.clear();
      _selectedGrade = 10;
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Note ajoutée avec succès'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur lors de l\'ajout'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addAbsence() async {
    if (_absenceReasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une raison'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _isAddingAbsence = true);
    
    final result = await ApiService.addAbsence(
      studentId: widget.student['_id'],
      date: DateTime.now(),
      justified: _absenceJustified,
      reason: _absenceReasonController.text,
    );
    
    setState(() => _isAddingAbsence = false);
    
    if (result['success']) {
      setState(() {
        _absences.insert(0, {
          'date': _getCurrentDate(),
          'justified': _absenceJustified,
          'reason': _absenceReasonController.text,
          'declaredBy': 'Mme Martin',
        });
      });
      
      _absenceReasonController.clear();
      _absenceJustified = false;
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Absence enregistrée'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur lors de l\'enregistrement'), backgroundColor: Colors.red),
      );
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  void _showAddGradeDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('➕ Ajouter une note'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Matière
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedSubject,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedSubject = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Note
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('Note: '),
                        Expanded(
                          child: Slider(
                            value: _selectedGrade,
                            min: 0,
                            max: 20,
                            divisions: 40,
                            label: _selectedGrade.toString(),
                            onChanged: (value) {
                              setDialogState(() {
                                _selectedGrade = value;
                                _gradeController.text = value.toString();
                              });
                            },
                            activeColor: const Color(0xFF0288D1),
                          ),
                        ),
                        Container(
                          width: 50,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0288D1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedGrade.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0288D1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Appréciation
                  TextField(
                    controller: _appreciationController,
                    decoration: InputDecoration(
                      hintText: 'Appréciation (optionnel)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ANNULER'),
              ),
              ElevatedButton(
                onPressed: _addGrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                ),
                child: _isAddingGrade
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('AJOUTER'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddAbsenceDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('📝 Enregistrer une absence'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF0288D1)),
                        const SizedBox(width: 12),
                        Text(
                          'Date: ${_getCurrentDate()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Justifié ou non
                  Row(
                    children: [
                      Checkbox(
                        value: _absenceJustified,
                        onChanged: (value) {
                          setDialogState(() {
                            _absenceJustified = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF4CAF9F),
                      ),
                      const Text('Absence justifiée'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Raison
                  TextField(
                    controller: _absenceReasonController,
                    decoration: InputDecoration(
                      hintText: 'Raison de l\'absence *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ANNULER'),
              ),
              ElevatedButton(
                onPressed: _addAbsence,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                ),
                child: _isAddingAbsence
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('ENREGISTRER'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          '👤 ${widget.student['fullName'] ?? 'Élève'}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'grade') {
                _showAddGradeDialog();
              } else if (value == 'absence') {
                _showAddAbsenceDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'grade',
                child: Row(
                  children: [
                    Icon(Icons.grade, color: Color(0xFF0288D1)),
                    SizedBox(width: 8),
                    Text('Ajouter une note'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'absence',
                child: Row(
                  children: [
                    Icon(Icons.event_busy, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Enregistrer absence'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Informations personnelles
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📋 INFORMATIONS PERSONNELLES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF01579B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Nom', widget.student['fullName']?.split(' ').first ?? '-'),
                        _buildInfoRow('Prénom', widget.student['fullName']?.split(' ').last ?? '-'),
                        _buildInfoRow('Classe', widget.student['className'] ?? '-'),
                        const Divider(height: 24),
                        const Text(
                          '📧 CONTACTS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF01579B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Email élève', widget.student['email'] ?? '-'),
                        _buildInfoRow('Email parent', widget.student['parentEmail'] ?? '-'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notes et appréciations
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '📊 NOTES ET APPRÉCIATIONS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF01579B),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Color(0xFF0288D1)),
                              onPressed: _showAddGradeDialog,
                              tooltip: 'Ajouter une note',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_grades.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text('Aucune note enregistrée'),
                            ),
                          )
                        else
                          ..._grades.map((grade) => _buildNoteRow(
                            grade['subject'],
                            grade['grade'],
                            grade['appreciation'],
                            _getGradeColor(grade['grade']),
                          )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Absences
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '📝 ABSENCES',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF01579B),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Color(0xFF0288D1)),
                              onPressed: _showAddAbsenceDialog,
                              tooltip: 'Ajouter une absence',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_absences.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text('Aucune absence enregistrée'),
                            ),
                          )
                        else
                          ..._absences.map((absence) => _buildAbsenceRow(
                            absence['date'],
                            absence['justified'],
                            absence['reason'],
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteRow(String subject, double grade, String appreciation, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(subject, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              grade.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(appreciation)),
        ],
      ),
    );
  }

  Widget _buildAbsenceRow(String date, bool justified, String reason) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              date,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: justified ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              justified ? 'Justifiée' : 'Non justifiée',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: justified ? Colors.green : Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 16) return Colors.green;
    if (grade >= 12) return Colors.blue;
    if (grade >= 10) return Colors.orange;
    return Colors.red;
  }
}