// lib/screens/student/student_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

class StudentScheduleScreen extends StatefulWidget {
  final String studentClass;

  const StudentScheduleScreen({super.key, required this.studentClass});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  bool _isLoading = true;
  Map<String, Map<int, Map<String, String>>> _schedule = {};
  int _selectedDayIndex = 0;
  
  final List<String> _days = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa'];
  final List<String> _fullDays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
  final List<String> _timeSlots = ['8h-9h', '9h-10h', '10h-11h', '11h-12h', '12h-13h'];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getStudentSchedule(widget.studentClass);
      if (result['success'] && result['schedule'] != null) {
        final scheduleData = result['schedule'];
        final Map<String, Map<int, Map<String, String>>> formattedSchedule = {};
        
        for (var day in _days) {
          formattedSchedule[day] = {};
          if (scheduleData[day] != null) {
            for (int i = 0; i < _timeSlots.length; i++) {
              final slot = scheduleData[day][i.toString()];
              if (slot != null && 
                  slot['subject'] != null && 
                  slot['subject'].toString().isNotEmpty) {
                formattedSchedule[day]![i] = {
                  'subject': slot['subject'].toString(),
                  'teacher': slot['teacher'].toString(),
                  'room': slot['room'].toString(),
                };
              } else {
                formattedSchedule[day]![i] = {
                  'subject': '', 
                  'teacher': '', 
                  'room': ''
                };
              }
            }
          } else {
            for (int i = 0; i < _timeSlots.length; i++) {
              formattedSchedule[day]![i] = {
                'subject': '', 
                'teacher': '', 
                'room': ''
              };
            }
          }
        }
        
        setState(() {
          _schedule = formattedSchedule;
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

  bool _hasCourse(int index) {
    final day = _days[_selectedDayIndex];
    final course = _schedule[day]?[index];
    if (course == null) return false;
    final subject = course['subject'];
    return subject != null && subject.isNotEmpty;
  }

  String _getSubject(int index) {
    final day = _days[_selectedDayIndex];
    final course = _schedule[day]?[index];
    if (course == null) return '';
    final subject = course['subject'];
    return (subject != null && subject.isNotEmpty) ? subject : '';
  }

  String _getTeacher(int index) {
    final day = _days[_selectedDayIndex];
    final course = _schedule[day]?[index];
    if (course == null) return '';
    final teacher = course['teacher'];
    return teacher ?? '';
  }

  String _getRoom(int index) {
    final day = _days[_selectedDayIndex];
    final course = _schedule[day]?[index];
    if (course == null) return '';
    final room = course['room'];
    return room ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Emploi du temps - ${widget.studentClass}'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sélecteur de jour
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Row(
                    children: List.generate(_fullDays.length, (index) {
                      final isSelected = _selectedDayIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDayIndex = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0288D1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              _fullDays[index].substring(0, 3),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Jour sélectionné
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: Color(0xFF0288D1)),
                      const SizedBox(width: 12),
                      Text(
                        _fullDays[_selectedDayIndex],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0288D1),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Liste des cours
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _timeSlots.length,
                    itemBuilder: (context, index) {
                      final hasCourse = _hasCourse(index);
                      final subject = _getSubject(index);
                      final teacher = _getTeacher(index);
                      final room = _getRoom(index);
                      final timeSlot = _timeSlots[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: hasCourse ? Colors.white : Colors.grey.shade50,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: hasCourse 
                                    ? const Color(0xFF0288D1).withOpacity(0.1)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  timeSlot,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: hasCourse ? const Color(0xFF0288D1) : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              hasCourse ? subject : 'Pas de cours',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: hasCourse ? Colors.black87 : Colors.grey,
                              ),
                            ),
                            subtitle: hasCourse
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Enseignant: $teacher',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'Salle: $room',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  )
                                : null,
                            // SUPPRESSION DU TRAILING (le badge "Présent" a été retiré)
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