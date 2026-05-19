import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'teacher_grade_students_screen.dart';

class TeacherDevoirScreen extends StatefulWidget {
  final String teacherEmail;
  final String className;
  final String teacherId;
  final String teacherSubject;
  final String teacherName;

  const TeacherDevoirScreen({
    super.key,
    required this.teacherEmail,
    required this.className,
    required this.teacherId,
    required this.teacherSubject,
    required this.teacherName,
  });

  @override
  State<TeacherDevoirScreen> createState() => _TeacherDevoirScreenState();
}

class _TeacherDevoirScreenState extends State<TeacherDevoirScreen> {
  bool _isLoading = true;
  bool _isAddingEvent = false;
  
  List<Map<String, dynamic>> _events = [];
  
  String _selectedType = 'Orale';
  String _selectedDay = 'Lu';
  String _selectedTimeSlot = '08h-09h';
  int _selectedDayNum = DateTime.now().day;
  int _selectedMonth = DateTime.now().month;
  
  final List<String> _eventTypes = ['Orale', 'Evaluation', 'Examen'];
  final List<String> _days = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa'];
  final List<String> _fullDays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
  final List<String> _timeSlots = [
    '08h-09h', '09h-10h', '10h-11h', '11h-12h', '12h-13h',
  ];
  
  final List<Map<String, dynamic>> _months = [
    {'num': 1, 'name': 'Janvier', 'days': 31},
    {'num': 2, 'name': 'Février', 'days': 28},
    {'num': 3, 'name': 'Mars', 'days': 31},
    {'num': 4, 'name': 'Avril', 'days': 30},
    {'num': 5, 'name': 'Mai', 'days': 31},
    {'num': 6, 'name': 'Juin', 'days': 30},
    {'num': 7, 'name': 'Juillet', 'days': 31},
    {'num': 8, 'name': 'Août', 'days': 31},
    {'num': 9, 'name': 'Septembre', 'days': 30},
    {'num': 10, 'name': 'Octobre', 'days': 31},
    {'num': 11, 'name': 'Novembre', 'days': 30},
    {'num': 12, 'name': 'Décembre', 'days': 31},
  ];
  
  List<int> _availableDays = [];

  @override
  void initState() {
    super.initState();
    _updateAvailableDays();
    _loadEvents();
  }

  void _updateAvailableDays() {
    int maxDays = _months.firstWhere((m) => m['num'] == _selectedMonth)['days'];
    if (_selectedMonth == 2 && _isLeapYear(DateTime.now().year)) {
      maxDays = 29;
    }
    _availableDays = List.generate(maxDays, (i) => i + 1);
    if (_selectedDayNum > maxDays) {
      _selectedDayNum = maxDays;
    }
  }

  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  // ✅ CORRECTION: Ajout du teacherId dans l'appel API
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getAgendaEvents(
        className: widget.className,
        teacherId: widget.teacherId, // 👈 AJOUT OBLIGATOIRE
      );
      
      if (result['success'] && mounted) {
        final dynamic eventsData = result['events'];
        List<Map<String, dynamic>> loadedEvents = [];
        
        if (eventsData is List) {
          for (var event in eventsData) {
            if (event is Map<String, dynamic>) {
              if (event['subject'] == widget.teacherSubject) {
                DateTime eventDate;
                try {
                  eventDate = DateTime.parse(event['date']);
                } catch (e) {
                  eventDate = DateTime.now();
                }
                
                loadedEvents.add({
                  'id': event['_id'] ?? event['id'],
                  'type': event['type'] ?? 'Orale',
                  'day': event['day'] ?? 'Lu',
                  'dayName': _getFullDay(event['day'] ?? 'Lu'),
                  'timeSlot': event['timeSlot'] ?? '08h-09h',
                  'date': eventDate,
                  'subject': event['subject'] ?? '',
                  'dayNum': eventDate.day,
                  'month': eventDate.month,
                });
              }
            }
          }
        }
        
        setState(() {
          _events = loadedEvents;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Erreur chargement événements: $e');
      setState(() => _isLoading = false);
    }
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

  // ✅ CORRECTION: Ajout du teacherId et teacherName dans l'appel API
  Future<void> _addEvent() async {
    setState(() => _isAddingEvent = true);
    
    try {
      final currentYear = DateTime.now().year;
      final date = DateTime(currentYear, _selectedMonth, _selectedDayNum);
      
      final result = await ApiService.addAgendaEvent(
        className: widget.className,
        subject: widget.teacherSubject,
        type: _selectedType,
        day: _selectedDay,
        timeSlot: _selectedTimeSlot,
        date: date,
        teacherId: widget.teacherId, // 👈 AJOUT OBLIGATOIRE
        teacherName: widget.teacherName, // 👈 AJOUT OBLIGATOIRE
      );
      
      if (mounted && result['success']) {
        await _loadEvents();
        _selectedType = 'Orale';
        _selectedDay = 'Lu';
        _selectedTimeSlot = '08h-09h';
        _selectedDayNum = DateTime.now().day;
        _selectedMonth = DateTime.now().month;
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ $_selectedType ajouté'), backgroundColor: Colors.green),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Erreur'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingEvent = false);
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer'),
        content: const Text('Voulez-vous vraiment supprimer cet événement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final result = await ApiService.deleteAgendaEvent(eventId);
              if (result['success']) {
                await _loadEvents();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🗑️ Événement supprimé'), backgroundColor: Colors.green),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'Erreur'), backgroundColor: Colors.red),
                  );
                }
                setState(() => _isLoading = false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    _selectedType = 'Orale';
    _selectedDay = 'Lu';
    _selectedTimeSlot = '08h-09h';
    _selectedDayNum = DateTime.now().day;
    _selectedMonth = DateTime.now().month;
    _updateAvailableDays();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_circle, color: Color(0xFF0288D1)),
                ),
                const SizedBox(width: 12),
                const Text('Ajouter'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedType,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _eventTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Row(
                            children: [
                              Icon(_getIconForType(type), size: 18, color: _getColorForType(type)),
                              const SizedBox(width: 8),
                              Text(type),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => _selectedType = value!);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedDay,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _days.map((day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(_getFullDay(day)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => _selectedDay = value!);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedTimeSlot,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _timeSlots.map((slot) {
                        return DropdownMenuItem<String>(
                          value: slot,
                          child: Text(slot),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => _selectedTimeSlot = value!);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<int>(
                      value: _selectedDayNum,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _availableDays.map((day) {
                        return DropdownMenuItem<int>(
                          value: day,
                          child: Text('Jour: $day'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => _selectedDayNum = value!);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _months.map<DropdownMenuItem<int>>((month) {
                        return DropdownMenuItem<int>(
                          value: month['num'] as int,
                          child: Text('Mois: ${month['name']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedMonth = value!;
                          _updateAvailableDays();
                          if (_selectedDayNum > _availableDays.length) {
                            _selectedDayNum = _availableDays.length;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0288D1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book, color: Color(0xFF0288D1)),
                        const SizedBox(width: 12),
                        Text('Matière: ${widget.teacherSubject}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
              ElevatedButton(
                onPressed: _addEvent,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0288D1)),
                child: _isAddingEvent 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('AJOUTER'),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch(type) {
      case 'Orale': return Icons.mic;
      case 'Evaluation': return Icons.assessment;
      case 'Examen': return Icons.science;
      default: return Icons.event;
    }
  }

  Color _getColorForType(String type) {
    switch(type) {
      case 'Orale': return Colors.deepPurple;
      case 'Evaluation': return Colors.teal;
      case 'Examen': return Colors.red;
      default: return const Color(0xFF0288D1);
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: const Color(0xFF0288D1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📝 ÉVALUATIONS & EXAMENS',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
                      ),
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
                    ],
                  ),
                ),
                
                Expanded(
                  child: _events.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune évaluation ou examen',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Appuyez sur + pour ajouter',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            final date = event['date'] as DateTime;
                            final isPast = date.isBefore(DateTime.now());
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeacherGradeStudentsScreen(
                                        className: widget.className,
                                        teacherSubject: widget.teacherSubject,
                                        teacherId: widget.teacherId,
                                        teacherName: widget.teacherName,
                                        examEvent: event,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: isPast ? Border.all(color: Colors.grey.shade300) : null,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: _getColorForType(event['type']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${date.day}',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: _getColorForType(event['type']),
                                            ),
                                          ),
                                          Text(
                                            _getMonthAbbreviation(date.month),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _getColorForType(event['type']),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Icon(
                                          _getIconForType(event['type']),
                                          size: 16,
                                          color: _getColorForType(event['type']),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          event['type'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            decoration: isPast ? TextDecoration.lineThrough : null,
                                            color: isPast ? Colors.grey : _getColorForType(event['type']),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0288D1).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.edit_note, size: 12, color: Color(0xFF0288D1)),
                                              SizedBox(width: 4),
                                              Text('Noter', style: TextStyle(fontSize: 10, color: Color(0xFF0288D1))),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          '${event['dayName']} ${event['timeSlot']}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        Text(
                                          '${event['dayNum']}/${event['month']}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                        ),
                                        Text(
                                          widget.teacherSubject,
                                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _deleteEvent(event['id']),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}