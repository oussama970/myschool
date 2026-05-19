import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'teacher_student_detail_screen.dart';

class TeacherClassScreen extends StatefulWidget {
  final String teacherEmail;
  final String className;
  final String teacherId;
  final String teacherName;
  final String teacherSubject;

  const TeacherClassScreen({
    super.key,
    required this.teacherEmail,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.teacherSubject,
  });

  @override
  State<TeacherClassScreen> createState() => _TeacherClassScreenState();
}

class _TeacherClassScreenState extends State<TeacherClassScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _students = [];
  String? _teacherSubject;
  
  // Variables pour l'absence en masse
  bool _isAbsenceMode = false;
  Map<String, bool> _selectedStudents = {};
  Map<String, dynamic>? _selectedScheduleSlot;
  List<Map<String, dynamic>> _teacherScheduleSlots = [];
  bool _isLoadingSchedule = false;
  bool _isSavingAbsences = false;
  
  // Pour suivre les élèves déjà absents
  Map<String, List<String>> _existingAbsences = {}; // studentId -> liste des dates d'absences

  final Map<String, String> _dayMapping = {
    'Lu': 'Lundi',
    'Ma': 'Mardi',
    'Me': 'Mercredi',
    'Je': 'Jeudi',
    'Ve': 'Vendredi',
    'Sa': 'Samedi',
  };

  final List<String> _timeSlots = [
    '08h-09h', '09h-10h', '10h-11h', '11h-12h', '12h-13h',
  ];

  @override
  void initState() {
    super.initState();
    _teacherSubject = widget.teacherSubject;
    _loadStudents();
    _loadTeacherInfo();
    _loadTeacherSchedule();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherSchedule() async {
    setState(() => _isLoadingSchedule = true);
    
    try {
      final result = await ApiService.getTeacherSchedule(
        widget.teacherEmail,
        widget.className
      );
      
      if (result['success'] && mounted) {
        final List<dynamic> slots = result['teacherSlots'] ?? [];
        setState(() {
          _teacherScheduleSlots = slots.map((slot) => ({
            'day': slot['day'],
            'dayName': slot['dayName'],
            'slotIndex': slot['slotIndex'],
            'timeSlot': slot['timeSlot'],
            'subject': slot['subject'],
            'room': slot['room'],
            'startHour': slot['startHour'],
            'endHour': slot['endHour'],
          })).toList();
          _isLoadingSchedule = false;
        });
      } else {
        setState(() => _isLoadingSchedule = false);
      }
    } catch (e) {
      print('❌ Erreur chargement agenda: $e');
      setState(() => _isLoadingSchedule = false);
    }
  }

  Future<void> _loadTeacherInfo() async {
    try {
      final result = await ApiService.getTeacherInfo(widget.teacherEmail);
      if (result['success'] && mounted) {
        final subjects = result['subjects'] ?? [];
        if (subjects.isNotEmpty && _teacherSubject == null) {
          setState(() {
            _teacherSubject = subjects[0];
          });
        }
      }
    } catch (e) {
      print('Erreur chargement info enseignant: $e');
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getStudentsByClass(widget.className);
      
      if (result['success']) {
        final students = result['students'] ?? [];
        
        // Charger les absences existantes pour chaque élève
        for (var student in students) {
          final studentId = student['_id'];
          final absencesResult = await ApiService.getStudentAbsences(studentId);
          if (absencesResult['success'] && absencesResult['absences'] != null) {
            final List<dynamic> absences = absencesResult['absences'];
            final List<String> absenceDates = absences.map((a) {
              final date = DateTime.parse(a['date']);
              return _formatDateKey(date);
            }).toList();
            _existingAbsences[studentId] = absenceDates;
          } else {
            _existingAbsences[studentId] = [];
          }
        }
        
        setState(() {
          _students = students;
          _selectedStudents = {};
          for (var student in students) {
            _selectedStudents[student['_id']] = false;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _students = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception: $e');
      setState(() {
        _students = [];
        _isLoading = false;
      });
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  bool _isStudentAlreadyAbsent(String studentId, DateTime absenceDate) {
    final dateKey = _formatDateKey(absenceDate);
    final existingDates = _existingAbsences[studentId] ?? [];
    return existingDates.contains(dateKey);
  }

  List<dynamic> _getFilteredStudents() {
    if (_searchController.text.isEmpty) return _students;
    return _students.where((s) =>
      s['fullName'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
      s['email'].toString().toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
  }

  void _startAbsenceMode() {
    setState(() {
      _isAbsenceMode = true;
      _selectedScheduleSlot = null;
      _selectedStudents = {};
      for (var student in _students) {
        _selectedStudents[student['_id']] = false;
      }
    });
    _showScheduleSelectionDialog();
  }

  void _cancelAbsenceMode() {
    setState(() {
      _isAbsenceMode = false;
      _selectedScheduleSlot = null;
      _selectedStudents = {};
    });
  }

  void _showScheduleSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Sélectionner le créneau'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoadingSchedule)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_teacherScheduleSlots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Aucun cours programmé pour vous dans cette classe',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _teacherScheduleSlots.map((slot) {
                        final isSelected = _selectedScheduleSlot == slot;
                        return FilterChip(
                          label: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_dayMapping[slot['day']] ?? slot['day']}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                slot['timeSlot'],
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              _selectedScheduleSlot = selected ? slot : null;
                            });
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: Colors.orange.withOpacity(0.2),
                          checkmarkColor: Colors.orange,
                        );
                      }).toList(),
                    ),
                  
                  if (_selectedScheduleSlot != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.menu_book, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Text('Matière: ${_selectedScheduleSlot!['subject']}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.meeting_room, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Text('Salle: ${_selectedScheduleSlot!['room']}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Text('Horaire: ${_selectedScheduleSlot!['timeSlot']}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelAbsenceMode();
                },
                child: const Text('ANNULER'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_selectedScheduleSlot != null) {
                    Navigator.pop(context);
                    _updateStudentAbsenceStatus();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez sélectionner un créneau'), backgroundColor: Colors.orange),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1)),
                child: const Text('SUIVANT'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateStudentAbsenceStatus() {
    if (_selectedScheduleSlot == null) return;
    
    final now = DateTime.now();
    final absenceDate = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedScheduleSlot!['startHour'],
      0,
    );
    final dateKey = _formatDateKey(absenceDate);
    
    setState(() {
      _selectedStudents = {};
      for (var student in _students) {
        final studentId = student['_id'];
        final isAlreadyAbsent = _existingAbsences[studentId]?.contains(dateKey) ?? false;
        _selectedStudents[studentId] = false;
      }
    });
    
    // Afficher un message d'information sur les élèves déjà absents
    final alreadyAbsentStudents = _students.where((student) {
      final studentId = student['_id'];
      return _existingAbsences[studentId]?.contains(dateKey) ?? false;
    }).toList();
    
    if (alreadyAbsentStudents.isNotEmpty) {
      final names = alreadyAbsentStudents.map((s) => s['fullName']).take(3).join(', ');
      final message = alreadyAbsentStudents.length > 3 
          ? '$names et ${alreadyAbsentStudents.length - 3} autres sont déjà absents pour cette séance'
          : '$names sont déjà absents pour cette séance';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ $message'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _saveAbsences() async {
    if (_selectedScheduleSlot == null) {
      _showSnackBar('Veuillez sélectionner un créneau', Colors.orange);
      return;
    }

    final selectedStudentIds = _selectedStudents.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedStudentIds.isEmpty) {
      _showSnackBar('Veuillez sélectionner au moins un élève', Colors.orange);
      return;
    }

    setState(() => _isSavingAbsences = true);

    try {
      final now = DateTime.now();
      final absenceDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedScheduleSlot!['startHour'],
        0,
      );
      final dateKey = _formatDateKey(absenceDateTime);

      int successCount = 0;
      int errorCount = 0;
      int alreadyAbsentCount = 0;

      for (var studentId in selectedStudentIds) {
        // Vérifier si l'élève est déjà absent pour cette séance
        if (_existingAbsences[studentId]?.contains(dateKey) == true) {
          alreadyAbsentCount++;
          continue;
        }
        
        final result = await ApiService.addAbsence(
          studentId: studentId,
          date: absenceDateTime,
          justified: true,
          reason: 'Absence pendant le cours',
          subject: _selectedScheduleSlot!['subject'],
        );
        
        if (result['success']) {
          successCount++;
          // Mettre à jour la liste locale
          if (!_existingAbsences.containsKey(studentId)) {
            _existingAbsences[studentId] = [];
          }
          _existingAbsences[studentId]!.add(dateKey);
        } else {
          errorCount++;
        }
      }

      setState(() => _isSavingAbsences = false);

      if (successCount > 0) {
        _showSnackBar('✅ $successCount absence(s) enregistrée(s)', Colors.green);
        if (alreadyAbsentCount > 0) {
          _showSnackBar('⚠️ $alreadyAbsentCount élève(s) déjà absent(s) pour cette séance', Colors.orange);
        }
        if (errorCount > 0) {
          _showSnackBar('❌ $errorCount erreur(s)', Colors.red);
        }
        
        // Réinitialiser la sélection
        setState(() {
          _selectedStudents = {};
          for (var student in _students) {
            _selectedStudents[student['_id']] = false;
          }
        });
        
        _cancelAbsenceMode();
        await _loadStudents();
      } else if (alreadyAbsentCount > 0 && successCount == 0) {
        _showSnackBar('⚠️ Tous les élèves sélectionnés sont déjà absents', Colors.orange);
      } else {
        _showSnackBar('❌ Erreur lors de l\'enregistrement', Colors.red);
      }
    } catch (e) {
      setState(() => _isSavingAbsences = false);
      _showSnackBar('Erreur: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _toggleSelectAll(bool? selected) {
    setState(() {
      final now = DateTime.now();
      final absenceDate = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedScheduleSlot?['startHour'] ?? 0,
        0,
      );
      final dateKey = _formatDateKey(absenceDate);
      
      for (var student in _students) {
        final studentId = student['_id'];
        final isAlreadyAbsent = _existingAbsences[studentId]?.contains(dateKey) ?? false;
        // Ne pas permettre de sélectionner les élèves déjà absents
        if (!isAlreadyAbsent) {
          _selectedStudents[studentId] = selected ?? false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _getFilteredStudents();
    final selectedCount = _selectedStudents.values.where((v) => v).toList().length;
    
    // Calculer le nombre d'élèves déjà absents pour la séance en cours
    final now = DateTime.now();
    final absenceDate = _selectedScheduleSlot != null ? DateTime(
      now.year,
      now.month,
      now.day,
      _selectedScheduleSlot!['startHour'],
      0,
    ) : null;
    final dateKey = absenceDate != null ? _formatDateKey(absenceDate) : null;
    
    final alreadyAbsentCount = dateKey != null ? _students.where((student) {
      return _existingAbsences[student['_id']]?.contains(dateKey) ?? false;
    }).toList().length : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: _isAbsenceMode ? null : FloatingActionButton(
        onPressed: _startAbsenceMode,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.event_busy, color: Colors.white),
        tooltip: 'Enregistrer des absences',
      ),
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
                    _isAbsenceMode 
                        ? '📝 Sélectionner les absents (${selectedCount}/${filteredStudents.length - alreadyAbsentCount})'
                        : '👥 Mes élèves (${_students.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF01579B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isAbsenceMode 
                          ? Colors.orange.withOpacity(0.1)
                          : const Color(0xFF0288D1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isAbsenceMode ? Icons.event_busy : Icons.people,
                      color: _isAbsenceMode ? Colors.orange : const Color(0xFF0288D1),
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
                  enabled: !_isAbsenceMode,
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

            if (_isAbsenceMode && _selectedScheduleSlot != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_dayMapping[_selectedScheduleSlot!['day']]} ${_selectedScheduleSlot!['timeSlot']} - ${_selectedScheduleSlot!['subject']} (Salle ${_selectedScheduleSlot!['room']})',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.orange),
                      onPressed: _showScheduleSelectionDialog,
                      tooltip: 'Changer de créneau',
                    ),
                  ],
                ),
              ),

            if (_isAbsenceMode && alreadyAbsentCount > 0)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$alreadyAbsentCount élève(s) déjà absent(s) pour cette séance',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStudents.isEmpty
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
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            final isSelected = _selectedStudents[student['_id']] ?? false;
                            
                            // Vérifier si l'élève est déjà absent pour cette séance
                            final now = DateTime.now();
                            final absenceDate = _selectedScheduleSlot != null ? DateTime(
                              now.year,
                              now.month,
                              now.day,
                              _selectedScheduleSlot!['startHour'],
                              0,
                            ) : null;
                            final dateKey = absenceDate != null ? _formatDateKey(absenceDate) : null;
                            final isAlreadyAbsent = dateKey != null && (_existingAbsences[student['_id']]?.contains(dateKey) ?? false);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: _isAbsenceMode
                                  ? CheckboxListTile(
                                      value: isSelected,
                                      onChanged: isAlreadyAbsent ? null : (selected) {
                                        setState(() {
                                          _selectedStudents[student['_id']] = selected ?? false;
                                        });
                                      },
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              student['fullName'] ?? '',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isAlreadyAbsent ? Colors.grey : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (isAlreadyAbsent)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Déjà absent',
                                                style: TextStyle(fontSize: 10, color: Colors.grey),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student['email'] ?? '',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isAlreadyAbsent ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0288D1).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Matière: ${_teacherSubject ?? widget.teacherSubject}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isAlreadyAbsent ? Colors.grey[400] : const Color(0xFF0288D1),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      controlAffinity: ListTileControlAffinity.leading,
                                      contentPadding: const EdgeInsets.all(16),
                                      secondary: isSelected && !isAlreadyAbsent
                                          ? const Icon(Icons.check_circle, color: Colors.orange)
                                          : null,
                                    )
                                  : InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TeacherStudentDetailScreen(
                                              student: student,
                                              teacherId: widget.teacherId,
                                              teacherName: widget.teacherName,
                                              teacherSubject: _teacherSubject ?? widget.teacherSubject,
                                              teacherEmail: widget.teacherEmail,
                                              className: widget.className,
                                            ),
                                          ),
                                        ).then((_) {
                                          _loadStudents();
                                        });
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
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF0288D1).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      'Matière: ${_teacherSubject ?? widget.teacherSubject}',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: const Color(0xFF0288D1),
                                                        fontWeight: FontWeight.w500,
                                                      ),
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
      bottomNavigationBar: _isAbsenceMode
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelAbsenceMode,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('ANNULER'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveAbsences,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: _isSavingAbsences
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('ENREGISTRER (${selectedCount})'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}