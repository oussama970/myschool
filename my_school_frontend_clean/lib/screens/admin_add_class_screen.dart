import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

class AdminAddClassScreen extends StatefulWidget {
  final String adminEmail;

  const AdminAddClassScreen({super.key, required this.adminEmail});

  @override
  State<AdminAddClassScreen> createState() => _AdminAddClassScreenState();
}

class _AdminAddClassScreenState extends State<AdminAddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _capacityController = TextEditingController();
  
  bool _isLoading = false;
  bool _isStep1 = true;
  String? _selectedLevel;
  String? _selectedGroup;
  
  List<String> _availableTeachers = [];
  
  final List<String> _roomsList = [
    '101', '102', '103', '104', '105', '106', '107', '108',
    '109', '110', '201', '202', '203', '204', '205', '206',
    'Labo Sciences', 'Labo Info', 'Salle Arts', 'Salle Musique', 
    'Bibliothèque', 'Gymnase', 'Salle de sport'
  ];
  
  final List<String> _days = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa'];
  final List<String> _fullDays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
  
  final List<String> _allTimeSlots = [
    '08h-09h', '09h-10h', '10h-11h', '11h-12h', '12h-13h',
  ];
  
  final List<String> _subjects = [
    'Maths', 'Français', 'Arabe', 'Anglais', 'Sciences', 
    'Islamique', 'Dessin', 'Musique', 'Sport', 'Informatique'
  ];
  
  late Map<String, Map<int, Map<String, String>>> _schedule;
  
  String _selectedDay = 'Lu';
  int _selectedSlot = 0;
  String _selectedSubject = '';
  String _selectedTeacher = '';
  String _selectedRoom = '';
  bool _isEditing = false;

  final List<String> _levels = [
    '1ère année', '2ème année', '3ème année', '4ème année', '5ème année', '6ème année'
  ];
  
  // MODIFICATION: Groupes A, B, C, D
  final List<String> _groups = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    _initSchedule();
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  void _initSchedule() {
    _schedule = {};
    for (var day in _days) {
      _schedule[day] = {};
      for (int i = 0; i < _allTimeSlots.length; i++) {
        _schedule[day]![i] = {'subject': '', 'teacher': '', 'room': ''};
      }
    }
  }

  Future<void> _loadTeachers() async {
    try {
      final result = await ApiService.getTeachersList();
      if (result['success']) {
        setState(() {
          _availableTeachers = List<String>.from(result['teachers'] ?? []);
        });
      }
    } catch (e) {
      setState(() {
        _availableTeachers = ['Prof Maths', 'Prof Français', 'Prof Anglais', 'Prof Sciences'];
      });
    }
  }

  String? _getClassName() {
    if (_selectedLevel != null && _selectedGroup != null) {
      return '$_selectedLevel $_selectedGroup';
    }
    return null;
  }

  bool _isScheduleComplete() {
    for (var day in _days) {
      for (int i = 0; i < _allTimeSlots.length; i++) {
        final course = _schedule[day]?[i];
        if (course == null || 
            course['subject']?.isEmpty == true || 
            course['teacher']?.isEmpty == true || 
            course['room']?.isEmpty == true) {
          return false;
        }
      }
    }
    return true;
  }

  int _getFilledSlotsCount() {
    int count = 0;
    for (var day in _days) {
      for (int i = 0; i < _allTimeSlots.length; i++) {
        final course = _schedule[day]?[i];
        if (course != null && 
            course['subject']?.isNotEmpty == true && 
            course['teacher']?.isNotEmpty == true && 
            course['room']?.isNotEmpty == true) {
          count++;
        }
      }
    }
    return count;
  }

  void _nextStep() {
    if (_selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une année'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (_selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un groupe'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() {
      _isStep1 = false;
    });
  }

  void _previousStep() {
    setState(() {
      _isStep1 = true;
    });
  }

  void _showAddEditDialog(String day, int slotIndex, {Map<String, String>? existing}) {
    _selectedDay = day;
    _selectedSlot = slotIndex;
    _selectedSubject = existing?['subject'] ?? '';
    _selectedTeacher = existing?['teacher'] ?? '';
    _selectedRoom = existing?['room'] ?? '';
    _isEditing = existing != null && (existing['subject'] ?? '').isNotEmpty;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(_isEditing ? '✏️ Modifier' : '➕ Ajouter', style: const TextStyle(fontSize: 16)),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Color(0xFF0288D1)),
                        const SizedBox(width: 10),
                        Text(
                          '${_getFullDay(_selectedDay)} ${_allTimeSlots[_selectedSlot]}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSubject.isEmpty ? null : _selectedSubject,
                    hint: const Text('Matière *'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _subjects.map((subject) {
                      return DropdownMenuItem(value: subject, child: Text(subject));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => _selectedSubject = value!);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedTeacher.isEmpty ? null : _selectedTeacher,
                    hint: const Text('Enseignant *'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _availableTeachers.map((teacher) {
                      return DropdownMenuItem(value: teacher, child: Text(teacher));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => _selectedTeacher = value!);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedRoom.isEmpty ? null : _selectedRoom,
                    hint: const Text('Salle *'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _roomsList.map((room) {
                      return DropdownMenuItem(value: room, child: Text(room));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => _selectedRoom = value!);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ANNULER'),
              ),
              if (_isEditing)
                TextButton(
                  onPressed: () {
                    _deleteCourse();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('SUPPRIMER'),
                ),
              ElevatedButton(
                onPressed: () {
                  if (_selectedSubject.isNotEmpty && _selectedTeacher.isNotEmpty && _selectedRoom.isNotEmpty) {
                    _saveCourse();
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: Colors.orange),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1)),
                child: Text(_isEditing ? 'MODIFIER' : 'AJOUTER'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getFullDay(String day) {
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

  void _saveCourse() {
    setState(() {
      _schedule[_selectedDay]![_selectedSlot] = {
        'subject': _selectedSubject,
        'teacher': _selectedTeacher,
        'room': _selectedRoom,
      };
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isEditing ? '✅ Cours modifié' : '✅ Cours ajouté'), 
      backgroundColor: Colors.green, 
      duration: const Duration(milliseconds: 800)
    ));
  }

  void _deleteCourse() {
    setState(() {
      _schedule[_selectedDay]![_selectedSlot] = {'subject': '', 'teacher': '', 'room': ''};
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🗑️ Cours supprimé'), 
      backgroundColor: Colors.red, 
      duration: Duration(milliseconds: 800)
    ));
  }

  Future<void> _createClassOnly() async {
    if (_selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une année'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (_selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un groupe'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String level = _selectedLevel!;
      final String group = _selectedGroup!;
      final String className = '$level $group';
      final int capacity = int.tryParse(_capacityController.text) ?? 30;
      
      final classResult = await ApiService.addClass(
        level: level,
        group: group,
        className: className,
        teacher: '',
        capacity: capacity,
        room: '',
      );

      if (classResult['success'] != true) {
        throw Exception(classResult['message'] ?? 'Erreur inconnue');
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Succès'),
            content: Text('Classe "$className" créée avec succès !'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createClassWithSchedule() async {
    if (_selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une année'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (_selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un groupe'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (!_isScheduleComplete()) {
      final filled = _getFilledSlotsCount();
      final total = _days.length * _allTimeSlots.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Agenda incomplet: $filled/$total créneaux remplis. Remplissez toutes les heures ou cliquez sur "IGNORER"'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String level = _selectedLevel!;
      final String group = _selectedGroup!;
      final String className = '$level $group';
      final int capacity = int.tryParse(_capacityController.text) ?? 30;
      
      final classResult = await ApiService.addClass(
        level: level,
        group: group,
        className: className,
        teacher: '',
        capacity: capacity,
        room: '',
      );

      if (classResult['success'] != true) {
        throw Exception(classResult['message'] ?? 'Erreur inconnue');
      }

      final Map<String, dynamic> scheduleToSave = {};
      for (var day in _days) {
        scheduleToSave[day] = {};
        for (int i = 0; i < _allTimeSlots.length; i++) {
          final course = _schedule[day]?[i];
          final Map<String, dynamic> courseData = {
            'subject': course?['subject'] ?? '',
            'teacher': course?['teacher'] ?? '',
            'room': course?['room'] ?? '',
          };
          scheduleToSave[day][i.toString()] = courseData;
        }
      }
      
      final scheduleResult = await ApiService.saveSchedule(
        className: className,
        schedule: scheduleToSave,
      );

      if (mounted) {
        if (scheduleResult['success'] == true) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('✅ Succès'),
              content: Text('Classe "$className" créée avec son agenda complet !'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          throw Exception(scheduleResult['message'] ?? 'Erreur lors de la sauvegarde de l\'agenda');
        }
      }
    } catch (e) {
      print('❌ Erreur détaillée: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCreateOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Création de la classe'),
        content: const Text('Voulez-vous créer un agenda pour cette classe maintenant ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createClassOnly();
            },
            child: const Text('IGNORER'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextStep();
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF0288D1),
              foregroundColor: Colors.white,
            ),
            child: const Text('CRÉER AGENDA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? className = _getClassName();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Color(0xFF0288D1), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              _isStep1 ? 'Ajouter une classe' : 'Agenda - ${className ?? ""}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _isStep1 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              ),
      ),
      body: _isStep1 ? _buildStep1() : _buildStep2(),
    );
  }

  Widget _buildStep1() {
    final String? className = _getClassName();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF4CAF9F), Color(0xFF66BB6A)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: const Color(0xFF4CAF9F).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: const Icon(Icons.add_box, color: Colors.white, size: 35),
                      ),
                      const SizedBox(height: 16),
                      const Text('Ajouter une classe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF01579B))),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildDropdown(
                  label: 'Année *',
                  value: _selectedLevel,
                  items: _levels,
                  onChanged: (v) => setState(() => _selectedLevel = v),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Groupe *',
                  value: _selectedGroup,
                  items: _groups,
                  onChanged: (v) => setState(() => _selectedGroup = v),
                ),
                if (className != null) const SizedBox(height: 16),
                if (className != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF9F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF4CAF9F)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.class_, color: Color(0xFF4CAF9F)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(className, style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _capacityController,
                  label: 'Capacité maximale',
                  icon: Icons.people,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4CAF9F), Color(0xFF66BB6A)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF4CAF9F).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _showCreateOptions(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, 
                      shadowColor: Colors.transparent,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('CRÉER LA CLASSE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final totalSlots = _days.length * _allTimeSlots.length;
    final filledSlots = _getFilledSlotsCount();
    final isComplete = filledSlots == totalSlots;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📅 AGENDA',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0288D1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getClassName() ?? '',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0288D1)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                '$filledSlots/$totalSlots',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isComplete ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LinearProgressIndicator(
            value: filledSlots / totalSlots,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? Colors.green : const Color(0xFF0288D1),
            ),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 45,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0288D1),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8)),
                      ),
                      child: const Text(
                        'Horaires',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    ..._fullDays.map((day) => Container(
                      width: 70,
                      height: 45,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0288D1),
                        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.3))),
                      ),
                      child: Text(
                        day,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    )),
                  ],
                ),
                for (int i = 0; i < _allTimeSlots.length; i++)
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 55,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _allTimeSlots[i],
                          style: const TextStyle(fontSize: 10, color: Colors.black87),
                        ),
                      ),
                      for (String day in _days)
                        _buildScheduleCell(day, i),
                    ],
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('← RETOUR'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createClassWithSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('VALIDER ET CRÉER'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCell(String day, int slotIndex) {
    final course = _schedule[day]?[slotIndex];
    final hasCourse = course != null && course['subject']!.isNotEmpty;
    
    return GestureDetector(
      onTap: () => _showAddEditDialog(day, slotIndex, existing: hasCourse ? course : null),
      child: Container(
        width: 70,
        height: 55,
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: hasCourse ? const Color(0xFF0288D1).withOpacity(0.1) : Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: hasCourse
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      course!['subject']!.length > 8 ? course['subject']!.substring(0, 7) : course['subject']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Color(0xFF0288D1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      course['teacher']!.length > 10 ? course['teacher']!.substring(0, 9) : course['teacher']!,
                      style: const TextStyle(fontSize: 7, color: Colors.grey),
                    ),
                    Text(
                      course['room']!,
                      style: const TextStyle(fontSize: 7, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : Center(
                child: Icon(Icons.add_circle_outline, size: 20, color: Colors.grey.shade400),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF01579B)),
          prefixIcon: Icon(icon, color: const Color(0xFF4CAF9F)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF01579B)),
          border: InputBorder.none,
        ),
        hint: Text('Sélectionner ${label.toLowerCase()}'),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        isExpanded: true,
      ),
    );
  }
}