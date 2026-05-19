// lib/services/api/teacher_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class TeacherService {
  // ==================== INFORMATIONS ENSEIGNANT ====================
  static Future<Map<String, dynamic>> getTeacherInfo(String email) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/info/$email'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<String> assignedClasses = [];
        
        if (data.containsKey('classes') && data['classes'] != null) {
          if (data['classes'] is List) {
            assignedClasses = List<String>.from(data['classes']);
          } else if (data['classes'] is String && (data['classes'] as String).contains(',')) {
            assignedClasses = (data['classes'] as String).split(',').map((c) => c.trim()).toList();
          } else if (data['classes'] is String) {
            assignedClasses = [data['classes']];
          }
        }
        
        if (assignedClasses.isEmpty && data.containsKey('assignedClasses') && data['assignedClasses'] != null) {
          if (data['assignedClasses'] is List) {
            assignedClasses = List<String>.from(data['assignedClasses']);
          }
        }
        
        if (assignedClasses.isEmpty && data.containsKey('className') && data['className'] != null) {
          String className = data['className'].toString();
          if (className.contains(',')) {
            assignedClasses = className.split(',').map((c) => c.trim()).toList();
          } else {
            assignedClasses = [className];
          }
        }
        
        return {
          'success': true,
          'className': data['className'] ?? (assignedClasses.isNotEmpty ? assignedClasses[0] : ''),
          'subjects': data['subjects'] ?? [],
          'teacherName': data['teacherName'] ?? data['fullName'] ?? 'Enseignant',
          'teacherId': data['teacherId'] ?? data['_id'] ?? '',
          'classes': assignedClasses,
          'email': data['email'] ?? email,
          'phoneNumber': data['phoneNumber'] ?? '',
        };
      }
      return {
        'success': true,
        'className': 'CM2 A',
        'subjects': ['Maths', 'Français'],
        'teacherName': 'Enseignant',
        'teacherId': 'demo_id',
        'classes': ['CM2 A', 'CM2 B', 'CM1 A'],
        'email': email,
        'phoneNumber': '',
      };
    } catch (e) {
      return {
        'success': true,
        'className': 'CM2 A',
        'subjects': ['Maths', 'Français'],
        'teacherName': 'Enseignant',
        'teacherId': 'demo_id',
        'classes': ['CM2 A', 'CM2 B', 'CM1 A'],
        'email': email,
        'phoneNumber': '',
      };
    }
  }

  static Future<Map<String, dynamic>> getTeacherClasses() async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/my-classes'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<String> classes = [];
        if (data.containsKey('classes') && data['classes'] is List) {
          classes = List<String>.from(data['classes']);
        }
        return {'success': true, 'classes': classes};
      }
      return {'success': true, 'classes': ['CM2 A', 'CM2 B', 'CM1 A']};
    } catch (e) {
      return {'success': true, 'classes': ['CM2 A', 'CM2 B', 'CM1 A']};
    }
  }

  static Future<Map<String, dynamic>> getTeacherNotifications(String email) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/notifications/$email'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'unreadMessages': data['unreadMessages'] ?? 0,
          'pendingWorks': data['pendingWorks'] ?? 0,
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // ==================== GESTION DES ÉLÈVES ====================
  static Future<Map<String, dynamic>> getStudentsByClass(String className) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/students/${Uri.encodeComponent(className)}'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'students': data['students'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getStudentLinkedParents(String studentId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/students/$studentId/details'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final student = data['student'] ?? {};
        final List<dynamic> linkedParents = student['linkedParents'] ?? [];
        return {'success': true, 'parents': List<String>.from(linkedParents)};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'parents': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur', 'parents': []};
    }
  }

  static Future<Map<String, dynamic>> getAllStudents() async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/admin/students'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'students': data['students'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'students': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur', 'students': []};
    }
  }

  static Future<Map<String, dynamic>> addStudentsToClass({
    required String className,
    required List<String> studentIds,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/teacher/class/add-students'),
        headers: headers,
        body: jsonEncode({
          'className': className,
          'studentIds': studentIds,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout des élèves'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> removeStudentFromClass({
    required String studentId,
    required String className,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiClient.baseUrl}/teacher/class/remove-student'),
        headers: headers,
        body: jsonEncode({
          'studentId': studentId,
          'className': className,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors du retrait de l\'élève'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // ==================== GESTION DES LEÇONS ====================
  static Future<Map<String, dynamic>> getLessons(String className) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/lessons/${Uri.encodeComponent(className)}'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'lessons': data['lessons']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> addLesson({
    required String title,
    required String subject,
    required String description,
    required String type,
    required String className,
    String? deadline,
    List<Map<String, dynamic>> files = const [],
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/teacher/lessons'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'subject': subject,
          'description': description,
          'type': type,
          'className': className,
          'deadline': deadline,
          'files': files,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> updateLesson({
    required String id,
    required String title,
    required String subject,
    required String description,
    required String type,
    String? deadline,
    List<Map<String, dynamic>> files = const [],
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.put(
        Uri.parse('${ApiClient.baseUrl}/teacher/lessons/$id'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'subject': subject,
          'description': description,
          'type': type,
          'deadline': deadline,
          'files': files,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de la modification'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> deleteLesson(String id) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiClient.baseUrl}/teacher/lessons/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de la suppression'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // ==================== GESTION DES ÉVÉNEMENTS ====================
  static Future<Map<String, dynamic>> getTeacherEvents({
    required String className,
    required String teacherId,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/events/${Uri.encodeComponent(className)}?teacherId=$teacherId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'events': data['events'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'events': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur', 'events': []};
    }
  }

  static Future<Map<String, dynamic>> addEvent({
    required String title,
    required String description,
    required DateTime date,
    required String teacherId,
    required String teacherName,
    required String className,
    DateTime? responseDeadline,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/teacher/events'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'date': date.toIso8601String(),
          'teacherId': teacherId,
          'teacherName': teacherName,
          'className': className,
          'status': 'pending',
          'responseDeadline': responseDeadline?.toIso8601String(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'event': data['event']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiClient.baseUrl}/teacher/events/$eventId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de la suppression'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // ==================== AGENDA EVENTS ====================
  static Future<Map<String, dynamic>> getAgendaEvents({
    required String className,
    required String teacherId,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/agenda-events/${Uri.encodeComponent(className)}?teacherId=$teacherId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'events': data['events'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'events': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur', 'events': []};
    }
  }

  static Future<Map<String, dynamic>> addAgendaEvent({
    required String className,
    required String subject,
    required String type,
    required String day,
    required String timeSlot,
    required DateTime date,
    required String teacherId,
    required String teacherName,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/teacher/agenda-events'),
        headers: headers,
        body: jsonEncode({
          'className': className,
          'subject': subject,
          'type': type,
          'day': day,
          'timeSlot': timeSlot,
          'date': date.toIso8601String(),
          'teacherId': teacherId,
          'teacherName': teacherName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'event': data['event']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> deleteAgendaEvent(String eventId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiClient.baseUrl}/teacher/agenda-events/$eventId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de la suppression'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // ✅ NOUVELLE MÉTHODE: Récupérer tous les examens d'une classe avec les notes
  static Future<Map<String, dynamic>> getAllExamsByClass(String className, String studentId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/exams/${Uri.encodeComponent(className)}?studentId=$studentId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'events': data['events'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'events': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion', 'events': []};
    }
  }

  // ==================== NOTES D'EXAMEN ====================
  static Future<Map<String, dynamic>> addExamGrade({
    required String examId,
    required String studentId,
    required String studentName,
    required String subject,
    required double grade,
    required String appreciation,
    String? photoUrl,
    required String teacherName,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/teacher/exam-grades'),
        headers: headers,
        body: jsonEncode({
          'examId': examId,
          'studentId': studentId,
          'studentName': studentName,
          'subject': subject,
          'grade': grade,
          'appreciation': appreciation,
          'photoUrl': photoUrl,
          'teacherName': teacherName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getExamGrades(String examId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/exam-grades/$examId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'grades': data['grades'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'grades': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur', 'grades': []};
    }
  }

  static Future<Map<String, dynamic>> getStudentExamGrades(String studentId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/student/exam-grades/$studentId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'grades': data['grades'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'grades': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur', 'grades': []};
    }
  }

  // ==================== NOTES ET ABSENCES ====================
  static Future<Map<String, dynamic>> getStudentGrades(String studentId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/students/$studentId/grades'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'grades': data['grades'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'grades': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur', 'grades': []};
    }
  }

  static Future<Map<String, dynamic>> getStudentAbsences(String studentId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/students/$studentId/absences'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'absences': data['absences'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'absences': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur', 'absences': []};
    }
  }

  static Future<Map<String, dynamic>> addAbsence({
    required String studentId,
    required DateTime date,
    required bool justified,
    required String reason,
    required String subject,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/teacher/absences'),
        headers: headers,
        body: jsonEncode({
          'studentId': studentId,
          'date': date.toIso8601String(),
          'justified': justified,
          'reason': reason,
          'subject': subject,
        }),
      );

      final data = jsonDecode(response.body);
      print('📡 addAbsence - Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout'};
    } catch (e) {
      print('❌ Erreur addAbsence: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> addGrade({
    required String studentId,
    required String subject,
    required double grade,
    required String appreciation,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/teacher/grades'),
        headers: headers,
        body: jsonEncode({
          'studentId': studentId,
          'subject': subject,
          'grade': grade,
          'appreciation': appreciation,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> deleteGrade(String gradeId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiClient.baseUrl}/teacher/grades/$gradeId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de la suppression'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // ==================== AGENDA (EMPLOI DU TEMPS) ====================
  static Future<Map<String, dynamic>> saveSchedule({
    required String className,
    required Map<String, dynamic> schedule,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      
      final Map<String, dynamic> convertedSchedule = {};
      schedule.forEach((day, slots) {
        convertedSchedule[day] = {};
        if (slots is Map) {
          slots.forEach((slotIndex, slotData) {
            convertedSchedule[day][slotIndex.toString()] = slotData;
          });
        }
      });
      
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/teacher/schedule'),
        headers: headers,
        body: jsonEncode({
          'className': className,
          'schedule': convertedSchedule,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de la sauvegarde'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSchedule(String className) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/schedule/${Uri.encodeComponent(className)}'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'schedule': data['schedule']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getTeacherSchedule(String teacherEmail, String className) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/schedule/teacher/$teacherEmail/${Uri.encodeComponent(className)}'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'teacherSlots': data['teacherSlots'] ?? [],
          'subjects': data['subjects'] ?? [],
          'teacherName': data['teacherName'] ?? ''
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'teacherSlots': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur', 'teacherSlots': []};
    }
  }

  static Future<Map<String, dynamic>> getAllTeacherSchedules(String teacherEmail) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/schedule/teacher/$teacherEmail/all'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'schedules': data['schedules'] ?? {},
          'subjects': data['subjects'] ?? [],
          'teacherName': data['teacherName'] ?? ''
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'schedules': {}};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur', 'schedules': {}};
    }
  }

  // ==================== PROFIL ENSEIGNANT ====================
  static Future<Map<String, dynamic>> updateTeacherProfile({
    required String email,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.put(
        Uri.parse('${ApiClient.baseUrl}/teacher/profile'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> changeTeacherPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/teacher/change-password'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }
}