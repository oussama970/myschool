import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

class TeacherAgendaScreen extends StatefulWidget {
  final String teacherEmail;
  final String className;

  const TeacherAgendaScreen({
    super.key,
    required this.teacherEmail,
    required this.className,
  });

  @override
  State<TeacherAgendaScreen> createState() => _TeacherAgendaScreenState();
}

class _TeacherAgendaScreenState extends State<TeacherAgendaScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  final List<String> _days = ['L', 'M', 'M', 'J', 'V', 'S'];
  final List<String> _fullDays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
  
  // TOUS les créneaux horaires complets de 8h à 18h
  final List<String> _allTimeSlots = [
    '08h-09h',   // index 0
    '09h-10h',   // index 1
    '10h-11h',   // index 2
    '11h-12h',   // index 3
    '12h-14h',   // index 4 - Pause
    '14h-15h',   // index 5
    '15h-16h',   // index 6
    '16h-17h',   // index 7
    '17h-18h',   // index 8
  ];
  
  final int _pauseSlotIndex = 4;
  
  final List<String> _subjects = [
    'Maths', 'Français', 'Arabe', 'Anglais', 'Sciences', 
    'Histoire', 'Géo', 'Islamique', 'EPS', 'Arts', 
    'Musique', 'Techno', 'Info', 'Physique', 'Chimie',
    'Étude', 'Permanence', 'Sport', 'Dessin'
  ];
  
  final List<String> _rooms = [
    '101', '102', '103', '104', '105', '106', '107', '108',
    'Labo', 'Info', 'Gym', 'Arts', 'Musique', 'Bibliothèque'
  ];
  
  late Map<String, Map<int, Map<String, String>>> _schedule;
  
  String _selectedDay = 'L';
  int _selectedSlot = 0;
  String _selectedSubject = '';
  String _selectedRoom = '';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initSchedule();
    _loadSchedule();
  }

  void _initSchedule() {
    _schedule = {};
    for (var day in _days) {
      _schedule[day] = {};
      for (int i = 0; i < _allTimeSlots.length; i++) {
        if (i == _pauseSlotIndex) {
          _schedule[day]![i] = {'subject': 'PAUSE DÉJEUNER', 'room': 'Cantine'};
        } else {
          _schedule[day]![i] = {'subject': '', 'room': ''};
        }
      }
    }
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getSchedule(widget.className);
      
      if (result['success'] && result['schedule'] != null) {
        final savedSchedule = result['schedule'];
        
        for (var day in _days) {
          if (savedSchedule[day] != null) {
            for (int i = 0; i < _allTimeSlots.length; i++) {
              if (savedSchedule[day][i] != null) {
                _schedule[day]![i] = {
                  'subject': savedSchedule[day][i]['subject'] ?? '',
                  'room': savedSchedule[day][i]['room'] ?? '',
                };
              }
            }
          }
        }
      } else {
        _loadMockSchedule();
      }
    } catch (e) {
      _loadMockSchedule();
    }
    
    setState(() => _isLoading = false);
  }

  void _loadMockSchedule() {
    // Lundi - TOUS les créneaux remplis
    _schedule['L']![0] = {'subject': 'Maths', 'room': '101'};
    _schedule['L']![1] = {'subject': 'Français', 'room': '102'};
    _schedule['L']![2] = {'subject': 'Sciences', 'room': 'Labo'};
    _schedule['L']![3] = {'subject': 'Anglais', 'room': '103'};
    // Pause index 4
    _schedule['L']![5] = {'subject': 'Histoire', 'room': '104'};
    _schedule['L']![6] = {'subject': 'EPS', 'room': 'Gym'};
    _schedule['L']![7] = {'subject': 'Étude', 'room': '101'};
    _schedule['L']![8] = {'subject': 'Permanence', 'room': '102'};
    
    // Mardi - TOUS les créneaux remplis
    _schedule['M']![0] = {'subject': 'Arabe', 'room': '105'};
    _schedule['M']![1] = {'subject': 'Maths', 'room': '101'};
    _schedule['M']![2] = {'subject': 'Sciences', 'room': 'Labo'};
    _schedule['M']![3] = {'subject': 'Français', 'room': '102'};
    // Pause index 4
    _schedule['M']![5] = {'subject': 'Anglais', 'room': '103'};
    _schedule['M']![6] = {'subject': 'Arts', 'room': 'Arts'};
    _schedule['M']![7] = {'subject': 'Musique', 'room': 'Musique'};
    _schedule['M']![8] = {'subject': 'Sport', 'room': 'Gym'};
    
    // Mercredi - TOUS les créneaux remplis
    _schedule['M']![0] = {'subject': 'Physique', 'room': 'Labo'};
    _schedule['M']![1] = {'subject': 'Maths', 'room': '101'};
    _schedule['M']![2] = {'subject': 'Chimie', 'room': 'Labo'};
    _schedule['M']![3] = {'subject': 'Français', 'room': '102'};
    // Pause index 4
    _schedule['M']![5] = {'subject': 'Techno', 'room': 'Info'};
    _schedule['M']![6] = {'subject': 'Musique', 'room': 'Musique'};
    _schedule['M']![7] = {'subject': 'Dessin', 'room': 'Arts'};
    _schedule['M']![8] = {'subject': 'Étude', 'room': '103'};
    
    // Jeudi - TOUS les créneaux remplis
    _schedule['J']![0] = {'subject': 'Maths', 'room': '101'};
    _schedule['J']![1] = {'subject': 'Histoire', 'room': '104'};
    _schedule['J']![2] = {'subject': 'Géo', 'room': '104'};
    _schedule['J']![3] = {'subject': 'Français', 'room': '102'};
    // Pause index 4
    _schedule['J']![5] = {'subject': 'Musique', 'room': 'Musique'};
    _schedule['J']![6] = {'subject': 'Techno', 'room': 'Info'};
    _schedule['J']![7] = {'subject': 'Permanence', 'room': '105'};
    _schedule['J']![8] = {'subject': 'Sport', 'room': 'Gym'};
    
    // Vendredi - TOUS les créneaux remplis
    _schedule['V']![0] = {'subject': 'Anglais', 'room': '103'};
    _schedule['V']![1] = {'subject': 'Maths', 'room': '101'};
    _schedule['V']![2] = {'subject': 'Sciences', 'room': 'Labo'};
    _schedule['V']![3] = {'subject': 'Islamique', 'room': '105'};
    // Pause index 4
    _schedule['V']![5] = {'subject': 'EPS', 'room': 'Gym'};
    _schedule['V']![6] = {'subject': 'Arts', 'room': 'Arts'};
    _schedule['V']![7] = {'subject': 'Info', 'room': 'Info'};
    _schedule['V']![8] = {'subject': 'Étude', 'room': '104'};
    
    // Samedi - TOUS les créneaux remplis
    _schedule['S']![0] = {'subject': 'Français', 'room': '102'};
    _schedule['S']![1] = {'subject': 'Arabe', 'room': '105'};
    _schedule['S']![2] = {'subject': 'Maths', 'room': '101'};
    _schedule['S']![3] = {'subject': 'Histoire', 'room': '104'};
    // Pause index 4
    _schedule['S']![5] = {'subject': 'Sport', 'room': 'Gym'};
    _schedule['S']![6] = {'subject': 'Info', 'room': 'Info'};
    _schedule['S']![7] = {'subject': 'Musique', 'room': 'Musique'};
    _schedule['S']![8] = {'subject': 'Permanence', 'room': '103'};
  }

  Future<void> _saveScheduleToBackend() async {
    setState(() => _isSaving = true);
    
    // Sauvegarder TOUS les créneaux (mêmes les vides)
    final Map<String, dynamic> scheduleToSave = {};
    for (var day in _days) {
      scheduleToSave[day] = {};
      for (int i = 0; i < _allTimeSlots.length; i++) {
        scheduleToSave[day][i] = {
          'subject': _schedule[day]![i]?['subject'] ?? '',
          'room': _schedule[day]![i]?['room'] ?? '',
        };
      }
    }
    
    final result = await ApiService.saveSchedule(
      className: widget.className,
      schedule: scheduleToSave,
    );
    
    setState(() => _isSaving = false);
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Agenda sauvegardé'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
      );
    }
  }

  void _showAddEditDialog(String day, int slotIndex, {Map<String, String>? existing}) {
    if (slotIndex == _pauseSlotIndex) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏰ Pause déjeuner - non modifiable'), backgroundColor: Colors.orange, duration: Duration(seconds: 1)),
      );
      return;
    }
    
    _selectedDay = day;
    _selectedSlot = slotIndex;
    _selectedSubject = existing?['subject'] ?? '';
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
                    hint: const Text('Sélectionner une matière'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
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
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedRoom.isEmpty ? null : _selectedRoom,
                    hint: const Text('Sélectionner une salle'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _rooms.map((room) {
                      return DropdownMenuItem(
                        value: room,
                        child: Text(room),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedRoom = value!;
                      });
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
                  if (_selectedSubject.isNotEmpty && _selectedRoom.isNotEmpty) {
                    _saveCourse();
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                ),
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
      case 'L': return 'Lundi';
      case 'M': return 'Mardi';
      case 'M': return 'Mercredi';
      case 'J': return 'Jeudi';
      case 'V': return 'Vendredi';
      case 'S': return 'Samedi';
      default: return day;
    }
  }

  void _saveCourse() {
    setState(() {
      _schedule[_selectedDay]![_selectedSlot] = {'subject': _selectedSubject, 'room': _selectedRoom};
    });
    _saveScheduleToBackend();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isEditing ? '✅ Cours modifié' : '✅ Cours ajouté'), 
      backgroundColor: Colors.green, 
      duration: const Duration(milliseconds: 800)
    ));
  }

  void _deleteCourse() {
    setState(() {
      _schedule[_selectedDay]![_selectedSlot] = {'subject': '', 'room': ''};
    });
    _saveScheduleToBackend();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🗑️ Cours supprimé'), 
      backgroundColor: Colors.red, 
      duration: Duration(milliseconds: 800)
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // En-tête
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📅 AGENDA',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0288D1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              widget.className,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0288D1)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_isSaving)
                            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            IconButton(
                              icon: const Icon(Icons.save, color: Color(0xFF0288D1)),
                              onPressed: _saveScheduleToBackend,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Double Scroll
                Expanded(
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // En-tête jours
                              Row(
                                children: [
                                  Container(
                                    width: 75,
                                    height: 50,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0288D1),
                                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8)),
                                    ),
                                    child: const Text(
                                      'Horaires',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  ..._fullDays.map((day) => Container(
                                    width: 75,
                                    height: 50,
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
                              
                              // TOUS les créneaux
                              for (int i = 0; i < _allTimeSlots.length; i++)
                                Row(
                                  children: [
                                    Container(
                                      width: 75,
                                      height: 60,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: i == _pauseSlotIndex ? Colors.orange.withOpacity(0.15) : Colors.grey.shade100,
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        _allTimeSlots[i],
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: i == _pauseSlotIndex ? FontWeight.bold : FontWeight.normal,
                                          color: i == _pauseSlotIndex ? Colors.orange : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    for (String day in _days)
                                      _buildScheduleCell(day, i, _schedule[day]?[i] ?? {'subject': '', 'room': ''}),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildScheduleCell(String day, int slotIndex, Map<String, String> course) {
    final String subject = course['subject'] ?? '';
    final String room = course['room'] ?? '';
    final bool hasCourse = subject.isNotEmpty && subject != 'PAUSE DÉJEUNER';
    final bool isPauseSlot = slotIndex == _pauseSlotIndex;
    
    Color cellColor = Colors.white;
    if (isPauseSlot) {
      cellColor = Colors.orange.withOpacity(0.15);
    } else if (hasCourse) {
      cellColor = const Color(0xFF0288D1).withOpacity(0.1);
    }
    
    return GestureDetector(
      onTap: () => _showAddEditDialog(day, slotIndex, existing: hasCourse ? course : null),
      child: Container(
        width: 75,
        height: 60,
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: cellColor,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: hasCourse
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subject.length > 10 ? subject.substring(0, 9) : subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: Color(0xFF0288D1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      room,
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : isPauseSlot
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, size: 24, color: Colors.orange),
                        SizedBox(height: 2),
                        Text(
                          'PAUSE',
                          style: TextStyle(fontSize: 8, color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 24,
                      color: Colors.grey.shade400,
                    ),
                  ),
      ),
    );
  }
}