import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

/// Écran de gestion des emplois du temps pour l'administrateur
/// Permet de visualiser toutes les classes, leur statut d'agenda,
/// et d'accéder à l'éditeur d'emploi du temps pour chaque classe
class AdminScheduleScreen extends StatefulWidget {
  final String adminEmail;

  const AdminScheduleScreen({super.key, required this.adminEmail});

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen> {
  // ==================== VARIABLES D'ÉTAT ====================
  bool _isLoading = true;
  List<dynamic> _classes = [];
  Map<String, bool> _hasSchedule = {};
  Map<String, int> _filledSlots = {};

  // Liste des matières pour l'école primaire
  final List<String> _subjects = [
    'Maths', 'Français', 'Arabe', 'Anglais', 'Sciences', 
    'Islamique', 'Dessin', 'Musique', 'Sport', 'Informatique'
  ];

  // ==================== CYCLE DE VIE ====================
  
  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  // ==================== CHARGEMENT DES DONNÉES ====================
  
  /// Charge la liste des classes et vérifie le statut de leur agenda
  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getClasses();
      
      if (result['success']) {
        final classes = result['classes'] ?? [];
        
        // Vérifier le statut de l'agenda pour chaque classe
        for (var classe in classes) {
          final className = classe['name'];
          await _checkScheduleStatus(className);
        }
        
        setState(() {
          _classes = classes;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur chargement classes: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Vérifie si une classe a un agenda et compte les créneaux remplis
  Future<void> _checkScheduleStatus(String className) async {
    try {
      final result = await ApiService.getSchedule(className);
      
      if (result['success'] && result['schedule'] != null) {
        final schedule = result['schedule'];
        int filled = _countFilledSlots(schedule);
        
        setState(() {
          _hasSchedule[className] = true;
          _filledSlots[className] = filled;
        });
      } else {
        setState(() {
          _hasSchedule[className] = false;
          _filledSlots[className] = 0;
        });
      }
    } catch (e) {
      setState(() {
        _hasSchedule[className] = false;
        _filledSlots[className] = 0;
      });
    }
  }

  /// Compte le nombre de créneaux remplis dans un agenda
  int _countFilledSlots(Map<String, dynamic> schedule) {
    int count = 0;
    if (schedule == null) return 0;
    
    final days = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa'];
    for (var day in days) {
      if (schedule[day] != null) {
        for (int i = 0; i < 5; i++) {
          final slotKey = i.toString();
          if (schedule[day][slotKey] != null) {
            final subject = schedule[day][slotKey]['subject'] ?? '';
            if (subject.isNotEmpty && subject != 'null') {
              count++;
            }
          }
        }
      }
    }
    return count;
  }

  /// Vérifie si l'agenda d'une classe est complet (30/30 créneaux)
  bool _isScheduleComplete(String className) {
    return _filledSlots[className] == 30;
  }

  // ==================== GESTION DE L'AGENDA ====================
  
  /// Crée un agenda vide pour une classe
  Future<void> _createEmptySchedule(String className) async {
    setState(() => _isLoading = true);
    
    final Map<String, dynamic> emptySchedule = {};
    final days = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa'];
    
    for (var day in days) {
      emptySchedule[day] = {};
      for (int i = 0; i < 5; i++) {
        emptySchedule[day][i.toString()] = {
          'subject': '',
          'teacher': '',
          'room': ''
        };
      }
    }
    
    final result = await ApiService.saveSchedule(
      className: className,
      schedule: emptySchedule,
    );
    
    if (result['success']) {
      await _checkScheduleStatus(className);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Agenda vide créé pour $className'), backgroundColor: Colors.green),
      );
      _loadClasses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: ${result['message']}'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  /// Ouvre l'écran d'édition de l'agenda d'une classe
  void _viewAgenda(String className) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAgendaEditScreen(
          className: className,
          subjects: _subjects,
          onScheduleSaved: () async {
            await _checkScheduleStatus(className);
            await _loadClasses();
          },
        ),
      ),
    );
  }

  /// Affiche le dialogue de confirmation pour créer un agenda
  void _showCreateDialog(String className) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un agenda'),
        content: Text('Aucun agenda n\'existe pour $className. Voulez-vous en créer un ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createEmptySchedule(className);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1)),
            child: const Text('CRÉER'),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD UI ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadClasses,
              child: Column(
                children: [
                  // Titre
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      '📅 EMPLOI DU TEMPS',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
                    ),
                  ),
                  // Liste des classes
                  Expanded(
                    child: _classes.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _classes.length,
                            itemBuilder: (context, index) => _buildClassCard(_classes[index]),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Affiche l'état vide (aucune classe)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Aucune classe disponible', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  /// Construit la carte d'une classe
  Widget _buildClassCard(dynamic classe) {
    final className = classe['name'] ?? 'Classe';
    final hasSchedule = _hasSchedule[className] ?? false;
    final filled = _filledSlots[className] ?? 0;
    final isComplete = _isScheduleComplete(className);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Icône de statut
                _buildStatusIcon(isComplete, hasSchedule),
                const SizedBox(width: 16),
                // Informations de la classe
                Expanded(
                  child: _buildClassInfo(className, isComplete, hasSchedule, filled),
                ),
                // Bouton d'action
                IconButton(
                  icon: Icon(
                    Icons.edit_calendar,
                    color: const Color(0xFF0288D1),
                  ),
                  onPressed: () {
                    if (hasSchedule) {
                      _viewAgenda(className);
                    } else {
                      _showCreateDialog(className);
                    }
                  },
                  tooltip: hasSchedule ? 'Modifier agenda' : 'Créer agenda',
                ),
              ],
            ),
            // Barre de progression (si agenda existe mais incomplet)
            if (hasSchedule && !isComplete) _buildProgressBar(filled),
          ],
        ),
      ),
    );
  }

  /// Construit l'icône de statut de l'agenda
  Widget _buildStatusIcon(bool isComplete, bool hasSchedule) {
    Color iconColor;
    Color bgColor;
    
    if (isComplete) {
      iconColor = const Color(0xFF4CAF9F);
      bgColor = const Color(0xFF4CAF9F).withOpacity(0.1);
    } else if (hasSchedule) {
      iconColor = const Color(0xFF0288D1);
      bgColor = const Color(0xFF0288D1).withOpacity(0.1);
    } else {
      iconColor = Colors.orange;
      bgColor = Colors.orange.withOpacity(0.1);
    }
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.calendar_today,
        color: iconColor,
        size: 28,
      ),
    );
  }

  /// Construit les informations textuelles d'une classe
  Widget _buildClassInfo(String className, bool isComplete, bool hasSchedule, int filled) {
    String statusText;
    Color statusColor;
    
    if (isComplete) {
      statusText = '✓ Agenda complet';
      statusColor = const Color(0xFF4CAF9F);
    } else if (hasSchedule) {
      statusText = '📝 Agenda en cours';
      statusColor = const Color(0xFF0288D1);
    } else {
      statusText = '⚠️ Agenda vide';
      statusColor = Colors.orange;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(className, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF01579B))),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: statusColor),
              ),
            ),
            if (hasSchedule) ...[
              const SizedBox(width: 8),
              Text('$filled/30 créneaux', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ],
        ),
      ],
    );
  }

  /// Construit la barre de progression de l'agenda
  Widget _buildProgressBar(int filled) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LinearProgressIndicator(
        value: filled / 30,
        backgroundColor: Colors.grey.shade200,
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0288D1)),
        minHeight: 4,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ==================== ÉCRAN D'ÉDITION DE L'AGENDA ====================

/// Écran pour visualiser et modifier l'emploi du temps d'une classe
class AdminAgendaEditScreen extends StatefulWidget {
  final String className;
  final List<String> subjects;
  final VoidCallback onScheduleSaved;

  const AdminAgendaEditScreen({
    super.key,
    required this.className,
    required this.subjects,
    required this.onScheduleSaved,
  });

  @override
  State<AdminAgendaEditScreen> createState() => _AdminAgendaEditScreenState();
}

class _AdminAgendaEditScreenState extends State<AdminAgendaEditScreen> {
  // ==================== CONSTANTES ====================
  final List<String> _days = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa'];
  final List<String> _fullDays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
  final List<String> _allTimeSlots = ['08h-09h', '09h-10h', '10h-11h', '11h-12h', '12h-13h'];
  
  final List<String> _rooms = [
    '101', '102', '103', '104', '105', '106', '107', '108',
    '109', '110', '201', '202', '203', '204', '205', '206',
    'Labo Sciences', 'Labo Info', 'Salle Arts', 'Salle Musique', 
    'Bibliothèque', 'Gymnase', 'Salle de sport'
  ];
  
  // ==================== VARIABLES D'ÉTAT ====================
  bool _isLoading = true;
  bool _isSaving = false;
  late List<String> _subjects;
  late Map<String, Map<int, Map<String, String>>> _schedule;
  List<String> _availableTeachers = [];
  
  // Variables temporaires pour l'édition
  String _selectedDay = 'Lu';
  int _selectedSlot = 0;
  String _selectedSubject = '';
  String _selectedTeacher = '';
  String _selectedRoom = '';
  bool _isEditing = false;

  // ==================== CYCLE DE VIE ====================
  
  @override
  void initState() {
    super.initState();
    _subjects = widget.subjects;
    _initSchedule();
    _loadTeachers();
    _loadSchedule();
  }

  /// Initialise un agenda vide
  void _initSchedule() {
    _schedule = {};
    for (var day in _days) {
      _schedule[day] = {};
      for (int i = 0; i < _allTimeSlots.length; i++) {
        _schedule[day]![i] = {'subject': '', 'teacher': '', 'room': ''};
      }
    }
  }

  /// Charge la liste des enseignants depuis l'API
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

  /// Charge l'agenda existant depuis l'API
  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getSchedule(widget.className);
      
      if (result['success'] && result['schedule'] != null) {
        final savedSchedule = result['schedule'];
        
        for (var day in _days) {
          if (savedSchedule[day] != null) {
            for (int i = 0; i < _allTimeSlots.length; i++) {
              final slotKey = i.toString();
              if (savedSchedule[day][slotKey] != null) {
                final slotData = savedSchedule[day][slotKey];
                _schedule[day]![i] = {
                  'subject': slotData['subject'] ?? '',
                  'teacher': slotData['teacher'] ?? '',
                  'room': slotData['room'] ?? '',
                };
              }
            }
          }
        }
      }
    } catch (e) {
      print('Erreur chargement agenda: $e');
    }
    
    setState(() => _isLoading = false);
  }

  // ==================== GESTION DE L'AGENDA ====================
  
  /// Sauvegarde l'agenda modifié
  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);
    
    final Map<String, dynamic> scheduleToSave = {};
    for (var day in _days) {
      scheduleToSave[day] = {};
      for (int i = 0; i < _allTimeSlots.length; i++) {
        final course = _schedule[day]![i];
        scheduleToSave[day][i.toString()] = {
          'subject': course?['subject'] ?? '',
          'teacher': course?['teacher'] ?? '',
          'room': course?['room'] ?? '',
        };
      }
    }
    
    final result = await ApiService.saveSchedule(
      className: widget.className,
      schedule: scheduleToSave,
    );
    
    setState(() => _isSaving = false);
    
    if (result['success']) {
      widget.onScheduleSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Agenda sauvegardé'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur lors de la sauvegarde'), backgroundColor: Colors.red),
      );
    }
  }

  /// Affiche le dialogue d'ajout/modification d'un créneau
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
                  _buildDialogHeader(),
                  const SizedBox(height: 16),
                  _buildSubjectDropdown(setDialogState),
                  const SizedBox(height: 12),
                  _buildTeacherDropdown(setDialogState),
                  const SizedBox(height: 12),
                  _buildRoomDropdown(setDialogState),
                ],
              ),
            ),
            actions: _buildDialogActions(),
          );
        },
      ),
    );
  }

  /// Construit l'en-tête du dialogue (jour et horaire)
  Widget _buildDialogHeader() {
    return Container(
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
    );
  }

  /// Convertit un code jour en nom complet
  String _getFullDay(String day) {
    const map = {'Lu': 'Lundi', 'Ma': 'Mardi', 'Me': 'Mercredi', 'Je': 'Jeudi', 'Ve': 'Vendredi', 'Sa': 'Samedi'};
    return map[day] ?? day;
  }

  /// Dropdown pour la sélection de la matière
  Widget _buildSubjectDropdown(StateSetter setDialogState) {
    return DropdownButtonFormField<String>(
      value: _selectedSubject.isEmpty ? null : _selectedSubject,
      hint: const Text('Matière *'),
      isExpanded: true,
      decoration: _inputDecoration(),
      items: _subjects.map((subject) => DropdownMenuItem(value: subject, child: Text(subject))).toList(),
      onChanged: (value) => setDialogState(() => _selectedSubject = value!),
    );
  }

  /// Dropdown pour la sélection de l'enseignant
  Widget _buildTeacherDropdown(StateSetter setDialogState) {
    return DropdownButtonFormField<String>(
      value: _selectedTeacher.isEmpty ? null : _selectedTeacher,
      hint: const Text('Enseignant *'),
      isExpanded: true,
      decoration: _inputDecoration(),
      items: _availableTeachers.map((teacher) => DropdownMenuItem(value: teacher, child: Text(teacher))).toList(),
      onChanged: (value) => setDialogState(() => _selectedTeacher = value!),
    );
  }

  /// Dropdown pour la sélection de la salle
  Widget _buildRoomDropdown(StateSetter setDialogState) {
    return DropdownButtonFormField<String>(
      value: _selectedRoom.isEmpty ? null : _selectedRoom,
      hint: const Text('Salle *'),
      isExpanded: true,
      decoration: _inputDecoration(),
      items: _rooms.map((room) => DropdownMenuItem(value: room, child: Text(room))).toList(),
      onChanged: (value) => setDialogState(() => _selectedRoom = value!),
    );
  }

  /// Style des champs du formulaire
  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  /// Actions du dialogue (boutons Annuler, Supprimer, Valider)
  List<Widget> _buildDialogActions() {
    return [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
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
    ];
  }

  /// Sauvegarde un cours dans l'agenda
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

  /// Supprime un cours de l'agenda
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

  /// Compte le nombre de créneaux remplis
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

  // ==================== BUILD UI ====================
  
  @override
  Widget build(BuildContext context) {
    final totalSlots = _days.length * _allTimeSlots.length;
    final filledSlots = _getFilledSlotsCount();
    final isComplete = filledSlots == totalSlots;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('📅 Agenda - ${widget.className}'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        actions: [
          // Compteur de progression
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('$filledSlots/$totalSlots', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          // Bouton de sauvegarde
          if (_isSaving)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveSchedule, tooltip: 'Sauvegarder'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barre de progression
                _buildProgressBar(totalSlots, filledSlots, isComplete),
                // Tableau de l'agenda
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // En-têtes des jours
                          _buildDaysHeader(),
                          // Lignes des créneaux horaires
                          for (int i = 0; i < _allTimeSlots.length; i++) _buildTimeSlotRow(i),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Construit la barre de progression
  Widget _buildProgressBar(int totalSlots, int filledSlots, bool isComplete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progression', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('$filledSlots/$totalSlots', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isComplete ? Colors.green : Colors.orange)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: filledSlots / totalSlots,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(isComplete ? Colors.green : const Color(0xFF0288D1)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  /// Construit la ligne des en-têtes des jours
  Widget _buildDaysHeader() {
    return Row(
      children: [
        Container(
          width: 90,
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFF0288D1), borderRadius: const BorderRadius.only(topLeft: Radius.circular(8))),
          child: const Text('Horaires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
        ..._fullDays.map((day) => Container(
          width: 90,
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFF0288D1), border: Border(left: BorderSide(color: Colors.white.withOpacity(0.3)))),
          child: Text(day, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        )),
      ],
    );
  }

  /// Construit une ligne de créneaux horaires
  Widget _buildTimeSlotRow(int slotIndex) {
    return Row(
      children: [
        Container(
          width: 90,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300)),
          child: Text(_allTimeSlots[slotIndex], style: const TextStyle(fontSize: 10, color: Colors.black87)),
        ),
        for (String day in _days) _buildScheduleCell(day, slotIndex),
      ],
    );
  }

  /// Construit une cellule du tableau d'agenda
  Widget _buildScheduleCell(String day, int slotIndex) {
    final course = _schedule[day]?[slotIndex];
    final hasCourse = course != null && course['subject']!.isNotEmpty;
    
    return GestureDetector(
      onTap: () => _showAddEditDialog(day, slotIndex, existing: hasCourse ? course : null),
      child: Container(
        width: 90,
        height: 70,
        margin: const EdgeInsets.all(0.5),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: hasCourse ? const Color(0xFF0288D1).withOpacity(0.1) : Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: hasCourse
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    course!['subject']!.length > 8 ? course['subject']!.substring(0, 7) : course['subject']!,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: Color(0xFF0288D1)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    course['teacher']!.length > 10 ? course['teacher']!.substring(0, 9) : course['teacher']!, 
                    style: const TextStyle(fontSize: 8, color: Colors.grey), 
                    textAlign: TextAlign.center
                  ),
                  Text(
                    course['room']!, 
                    style: const TextStyle(fontSize: 8, color: Colors.grey), 
                    textAlign: TextAlign.center
                  ),
                ],
              )
            : const Center(child: Icon(Icons.add_circle_outline, size: 20, color: Colors.grey)),
      ),
    );
  }
}