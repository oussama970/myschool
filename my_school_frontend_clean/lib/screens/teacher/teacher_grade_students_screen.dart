// lib/screens/teacher/teacher_grade_students_screen.dart
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TeacherGradeStudentsScreen extends StatefulWidget {
  final String className;
  final String teacherSubject;
  final String teacherId;
  final String teacherName;
  final Map<String, dynamic> examEvent;

  const TeacherGradeStudentsScreen({
    super.key,
    required this.className,
    required this.teacherSubject,
    required this.teacherId,
    required this.teacherName,
    required this.examEvent,
  });

  @override
  State<TeacherGradeStudentsScreen> createState() => _TeacherGradeStudentsScreenState();
}

class _TeacherGradeStudentsScreenState extends State<TeacherGradeStudentsScreen> {
  List<Map<String, dynamic>> _students = [];
  Map<String, TextEditingController> _gradeControllers = {};
  Map<String, TextEditingController> _appreciationControllers = {};
  Map<String, String?> _photoUrls = {};
  Map<String, bool> _isPhotoUploading = {};
  bool _isLoading = true;
  bool _isSavingAll = false;
  bool _hasUnsavedChanges = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    for (var controller in _gradeControllers.values) {
      controller.dispose();
    }
    for (var controller in _appreciationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getStudentsByClass(widget.className);
      
      if (result['success'] && mounted) {
        final students = result['students'] ?? [];
        
        setState(() {
          _students = List<Map<String, dynamic>>.from(students);
          
          for (var student in _students) {
            final studentId = student['_id'].toString();
            _gradeControllers[studentId] = TextEditingController();
            _appreciationControllers[studentId] = TextEditingController();
            _photoUrls[studentId] = null;
            _isPhotoUploading[studentId] = false;
          }
          
          _isLoading = false;
        });
        
        await _loadExistingGrades();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Erreur chargement élèves: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingGrades() async {
    try {
      final result = await ApiService.getExamGrades(widget.examEvent['id']);
      if (result['success'] && mounted) {
        final grades = result['grades'] ?? [];
        for (var grade in grades) {
          final studentId = grade['studentId'];
          if (_gradeControllers.containsKey(studentId)) {
            _gradeControllers[studentId]?.text = grade['grade'].toString();
            _appreciationControllers[studentId]?.text = grade['appreciation'] ?? '';
            _photoUrls[studentId] = grade['photoUrl'];
          }
        }
        setState(() {});
      }
    } catch (e) {
      print('Erreur chargement notes existantes: $e');
    }
  }

  Future<void> _takePhoto(String studentId) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (photo != null) {
        final File file = File(photo.path);
        
        setState(() {
          _isPhotoUploading[studentId] = true;
        });
        
        final uploadResult = await ApiService.uploadFile(file);
        
        if (uploadResult['success'] && mounted) {
          setState(() {
            _photoUrls[studentId] = uploadResult['file']['filePath'];
            _isPhotoUploading[studentId] = false;
            _hasUnsavedChanges = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📸 Photo ajoutée'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          setState(() {
            _isPhotoUploading[studentId] = false;
          });
          throw Exception('Upload échoué');
        }
      }
    } catch (e) {
      setState(() {
        _isPhotoUploading[studentId] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onGradeChanged(String studentId) {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveAllGrades() async {
    setState(() => _isSavingAll = true);
    
    int savedCount = 0;
    int errorCount = 0;
    
    for (var student in _students) {
      final studentId = student['_id'].toString();
      final gradeText = _gradeControllers[studentId]?.text.trim() ?? '';
      
      if (gradeText.isNotEmpty) {
        final gradeValue = double.tryParse(gradeText);
        if (gradeValue != null && gradeValue >= 0 && gradeValue <= 20) {
          try {
            final result = await ApiService.addExamGrade(
              examId: widget.examEvent['id'],
              studentId: studentId,
              studentName: student['fullName'],
              subject: widget.teacherSubject,
              grade: gradeValue,
              appreciation: _appreciationControllers[studentId]?.text.trim() ?? '',
              photoUrl: _photoUrls[studentId],
              teacherName: widget.teacherName,
            );
            
            if (result['success']) {
              savedCount++;
            } else {
              errorCount++;
            }
          } catch (e) {
            errorCount++;
          }
        } else if (gradeText.isNotEmpty) {
          errorCount++;
        }
      }
    }
    
    setState(() {
      _isSavingAll = false;
      _hasUnsavedChanges = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $savedCount notes enregistrées'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    
    await _loadExistingGrades();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📝 ${widget.examEvent['type']}',
              style: const TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.examEvent['dayName']} ${widget.examEvent['timeSlot']}',
              style: TextStyle(
                fontSize: 13, 
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: _isSavingAll ? null : _saveAllGrades,
                icon: _isSavingAll
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_isSavingAll ? 'Enregistrement...' : 'Enregistrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0288D1),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // En-tête des colonnes
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0288D1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 45, child: Text('#', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                      const Expanded(flex: 2, child: Text('ÉLÈVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                      const SizedBox(width: 70, child: Text('NOTE', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                      const Expanded(flex: 3, child: Text('APPRÉCIATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                      const SizedBox(width: 50, child: Text('PHOTO', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Liste des élèves
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadStudents,
                    color: const Color(0xFF0288D1),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final studentId = student['_id'].toString();
                        final isPhotoUploading = _isPhotoUploading[studentId] ?? false;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              children: [
                                // Numéro
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0288D1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF0288D1),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 8),
                                
                                // Nom de l'élève
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    student['fullName'] ?? 'Élève',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                
                                // Champ Note
                                SizedBox(
                                  width: 65,
                                  child: TextField(
                                    controller: _gradeControllers[studentId],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '0-20',
                                      hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                    ),
                                    onChanged: (_) => _onGradeChanged(studentId),
                                  ),
                                ),
                                
                                const SizedBox(width: 10),
                                
                                // Champ Appréciation
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _appreciationControllers[studentId],
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: '...',
                                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    ),
                                    onChanged: (_) => _onGradeChanged(studentId),
                                  ),
                                ),
                                
                                const SizedBox(width: 8),
                                
                                // Icône photo
                                SizedBox(
                                  width: 45,
                                  child: Center(
                                    child: isPhotoUploading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : GestureDetector(
                                            onTap: () => _takePhoto(studentId),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: _photoUrls[studentId] != null
                                                    ? Colors.green.shade50
                                                    : Colors.orange.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _photoUrls[studentId] != null ? Icons.photo : Icons.camera_alt,
                                                color: _photoUrls[studentId] != null ? Colors.green : Colors.orange,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ],
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