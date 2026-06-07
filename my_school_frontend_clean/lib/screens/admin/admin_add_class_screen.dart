import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

/// Écran d'ajout d'une classe par l'administrateur
/// Permet de créer une classe avec ou sans agenda (emploi du temps)
class AdminAddClassScreen extends StatefulWidget {
  final String adminEmail;

  const AdminAddClassScreen({super.key, required this.adminEmail});

  @override
  State<AdminAddClassScreen> createState() => _AdminAddClassScreenState();
}

class _AdminAddClassScreenState extends State<AdminAddClassScreen> {
  // ==================== VARIABLES D'ÉTAT ====================
  final _formKey = GlobalKey<FormState>();
  final _capacityController = TextEditingController();
  
  bool _isLoading = false;
  bool _isStep1 = true;  // Step1: informations classe, Step2: agenda
  String? _selectedLevel;
  String? _selectedGroup;
  
  // ==================== DONNÉES POUR L'AGENDA ====================
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
  
  // Variables temporaires pour l'édition d'un créneau
  String _selectedDay = 'Lu';
  int _selectedSlot = 0;
  String _selectedSubject = '';
  String _selectedTeacher = '';
  String _selectedRoom = '';
  bool _isEditing = false;

  final List<String> _levels = [
    '1ère année', '2ème année', '3ème année', '4ème année', '5ème année', '6ème année'
  ];
  
  final List<String> _groups = ['A', 'B', 'C', 'D'];

  // ==================== CYCLE DE VIE ====================
  
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

  // ==================== MÉTHODES D'INITIALISATION ====================
  
  /// Initialise un agenda vide (tous les créneaux sont vides)
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
      // Données mockées en cas d'erreur
      setState(() {
        _availableTeachers = ['Prof Maths', 'Prof Français', 'Prof Anglais', 'Prof Sciences'];
      });
    }
  }

  // ==================== MÉTHODES UTILITAIRES ====================
  
  /// Retourne le nom complet de la classe (ex: "3ème année B")
  String? _getClassName() {
    if (_selectedLevel != null && _selectedGroup != null) {
      return '$_selectedLevel $_selectedGroup';
    }
    return null;
  }

  /// Vérifie si tous les créneaux de l'agenda sont remplis
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

  /// Compte le nombre de créneaux remplis dans l'agenda
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

  /// Convertit un code jour (Lu, Ma, Me...) en nom complet
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

  /// Affiche un message SnackBar à l'écran
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: color, 
        duration: const Duration(milliseconds: 800)
      )
    );
  }

  // ==================== NAVIGATION ENTRE LES ÉTAPES ====================
  
  /// Passe à l'étape 2 (création de l'agenda)
  void _nextStep() {
    if (_selectedLevel == null) {
      _showSnackBar('Veuillez sélectionner une année', Colors.orange);
      return;
    }
    
    if (_selectedGroup == null) {
      _showSnackBar('Veuillez sélectionner un groupe', Colors.orange);
      return;
    }
    
    setState(() {
      _isStep1 = false;
    });
  }

  /// Retour à l'étape 1 (informations de la classe)
  void _previousStep() {
    setState(() {
      _isStep1 = true;
    });
  }

  // ==================== GESTION DE L'AGENDA ====================
  
  /// Affiche le dialogue d'ajout ou modification d'un créneau
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
                  // En-tête avec jour et horaire
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
                  // Sélection de la matière
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
                  // Sélection de l'enseignant
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
                  // Sélection de la salle
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
                    _showSnackBar('Veuillez remplir tous les champs', Colors.orange);
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

  /// Sauvegarde le cours dans l'agenda
  void _saveCourse() {
    setState(() {
      _schedule[_selectedDay]![_selectedSlot] = {
        'subject': _selectedSubject,
        'teacher': _selectedTeacher,
        'room': _selectedRoom,
      };
    });
    _showSnackBar(_isEditing ? '✅ Cours modifié' : '✅ Cours ajouté', Colors.green);
  }

  /// Supprime un cours de l'agenda
  void _deleteCourse() {
    setState(() {
      _schedule[_selectedDay]![_selectedSlot] = {'subject': '', 'teacher': '', 'room': ''};
    });
    _showSnackBar('🗑️ Cours supprimé', Colors.red);
  }

  // ==================== CRÉATION DE LA CLASSE ====================
  
  /// Crée uniquement la classe (sans agenda)
  Future<void> _createClassOnly() async {
    if (_selectedLevel == null) {
      _showSnackBar('Veuillez sélectionner une année', Colors.orange);
      return;
    }
    
    if (_selectedGroup == null) {
      _showSnackBar('Veuillez sélectionner un groupe', Colors.orange);
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
        _showSnackBar('❌ Erreur: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Crée la classe avec son agenda complet
  Future<void> _createClassWithSchedule() async {
    if (_selectedLevel == null) {
      _showSnackBar('Veuillez sélectionner une année', Colors.orange);
      return;
    }
    
    if (_selectedGroup == null) {
      _showSnackBar('Veuillez sélectionner un groupe', Colors.orange);
      return;
    }
    
    if (!_isScheduleComplete()) {
      final filled = _getFilledSlotsCount();
      final total = _days.length * _allTimeSlots.length;
      _showSnackBar(
        '⚠️ Agenda incomplet: $filled/$total créneaux remplis. Remplissez toutes les heures.',
        Colors.orange
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String level = _selectedLevel!;
      final String group = _selectedGroup!;
      final String className = '$level $group';
      final int capacity = int.tryParse(_capacityController.text) ?? 30;
      
      // Étape 1: Créer la classe
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

      // Étape 2: Sauvegarder l'agenda
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
        _showSnackBar('❌ Erreur: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Affiche les options de création (avec ou sans agenda)
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

  // ==================== BUILD UI ====================
  
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

  /// Construit l'interface de la première étape (informations classe)
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
                // En-tête avec icône
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
                // Sélection de l'année
                _buildDropdown(
                  label: 'Année *',
                  value: _selectedLevel,
                  items: _levels,
                  onChanged: (v) => setState(() => _selectedLevel = v),
                ),
                const SizedBox(height: 16),
                // Sélection du groupe
                _buildDropdown(
                  label: 'Groupe *',
                  value: _selectedGroup,
                  items: _groups,
                  onChanged: (v) => setState(() => _selectedGroup = v),
                ),
                // Aperçu du nom de la classe
                if (className != null) ...[
                  const SizedBox(height: 16),
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
                ],
                const SizedBox(height: 16),
                // Capacité de la classe
                _buildTextField(
                  controller: _capacityController,
                  label: 'Capacité maximale',
                  icon: Icons.people,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                // Bouton de création
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

  /// Construit l'interface de la deuxième étape (agenda)
  Widget _buildStep2() {
    final totalSlots = _days.length * _allTimeSlots.length;
    final filledSlots = _getFilledSlotsCount();
    final isComplete = filledSlots == totalSlots;
    
    return Column(
      children: [
        // En-tête de l'agenda
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
        // Barre de progression
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progression', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
        // Tableau de l'agenda (scrollable)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ligne des en-têtes de jours
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
                // Lignes des créneaux horaires
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
        // Boutons de navigation
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

  /// Construit une cellule individuelle du tableau d'agenda
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

  /// Construit un champ de texte stylisé
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

  /// Construit un menu déroulant stylisé
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