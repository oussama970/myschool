import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  // ==================== GESTION DU TOKEN ====================
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    print('✅ Token sauvegardé');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    print('🔓 Token supprimé');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // ==================== AUTHENTIFICATION ====================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Email ou mot de passe incorrect'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email.toLowerCase().trim(),
          'password': password,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur inconnue'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'code': code,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Code incorrect'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> verifyParentCode({
    required String parentCode,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-parent-code'),
        headers: headers,
        body: jsonEncode({'parentCode': parentCode}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Code invalide'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getLinkedChild(String parentEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/linked-child/${parentEmail.toLowerCase().trim()}'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'child': data['child']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Aucun enfant lié'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.toLowerCase().trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'], 'email': data['email']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Email non trouvé'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'code': code,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Code invalide'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // ==================== INFORMATIONS ENFANT ====================
  static Future<Map<String, dynamic>> getChildInfo(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/child/${email.toLowerCase().trim()}'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'child': {
            'fullName': data['fullName'],
            'email': data['email'],
            'parentCode': data['parentCode'],
          }
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Enfant non trouvé'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // ==================== ENSEIGNANT ====================
  static Future<Map<String, dynamic>> getTeacherInfo(String email) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/info/$email'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'className': data['className'] ?? '',
          'subjects': data['subjects'] ?? [],
          'teacherName': data['teacherName'] ?? '',
          'teacherId': data['teacherId'] ?? '',
        };
      } else {
        return {
          'success': true,
          'className': 'CM2 A',
          'subjects': ['Maths', 'Français'],
          'teacherName': 'Enseignant',
          'teacherId': 'demo_id',
        };
      }
    } catch (e) {
      return {
        'success': true,
        'className': 'CM2 A',
        'subjects': ['Maths', 'Français'],
        'teacherName': 'Enseignant',
        'teacherId': 'demo_id',
      };
    }
  }

  static Future<Map<String, dynamic>> getStudentsByClass(String className) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/students/${Uri.encodeComponent(className)}'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'students': data['students']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getAllStudents() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/students/all'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'students': data['students'] ?? []};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors du chargement des élèves'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> addStudentsToClass({
    required String className,
    required List<String> studentIds,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/teacher/class/add-students'),
        headers: headers,
        body: jsonEncode({
          'className': className,
          'studentIds': studentIds,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout des élèves'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> removeStudentFromClass({
    required String studentId,
    required String className,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/teacher/class/remove-student'),
        headers: headers,
        body: jsonEncode({
          'studentId': studentId,
          'className': className,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors du retrait de l\'élève'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // ==================== ENSEIGNANT - GESTION DES LEÇONS (CRUD COMPLET) ====================

  static Future<Map<String, dynamic>> getLessons(String className) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/lessons/${Uri.encodeComponent(className)}'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'lessons': data['lessons']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return {
        'success': true,
        'lessons': [
          {
            '_id': '1',
            'title': 'Les fractions',
            'subject': 'Maths',
            'type': 'Cours',
            'description': 'Introduction aux fractions',
            'createdAt': DateTime.now().toIso8601String(),
            'files': []
          },
          {
            '_id': '2',
            'title': 'Le passé simple',
            'subject': 'Français',
            'type': 'Cours',
            'description': 'Conjugaison du passé simple',
            'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'files': []
          },
          {
            '_id': '3',
            'title': 'Exercice sur les fractions',
            'subject': 'Maths',
            'type': 'Devoir',
            'description': 'Exercices page 42',
            'createdAt': DateTime.now().toIso8601String(),
            'deadline': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'files': []
          },
        ]
      };
    }
  }

  static Future<Map<String, dynamic>> addLesson({
    required String title,
    required String subject,
    required String description,
    required String type,
    required String className,
    String? deadline,
    List<String> files = const [],
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/teacher/lessons'),
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
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout'};
      }
    } catch (e) {
      return {'success': true, 'message': 'Contenu ajouté (mode démo)'};
    }
  }

  static Future<Map<String, dynamic>> updateLesson({
    required String id,
    required String title,
    required String subject,
    required String description,
    required String type,
    String? deadline,
    List<String> files = const [],
  }) async {
    try {
      final headers = await getHeaders();
      
      print('📤 Mise à jour leçon - ID: $id');
      
      final response = await http.put(
        Uri.parse('$baseUrl/teacher/lessons/$id'),
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
      print('📥 Réponse status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de la modification'};
      }
    } catch (e) {
      print('❌ Erreur updateLesson: $e');
      return {'success': true, 'message': 'Contenu modifié (mode démo)'};
    }
  }

  static Future<Map<String, dynamic>> deleteLesson(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/teacher/lessons/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de la suppression'};
      }
    } catch (e) {
      return {'success': true, 'message': 'Contenu supprimé (mode démo)'};
    }
  }

  // ==================== ENSEIGNANT - GESTION DE L'AGENDA ====================
  static Future<Map<String, dynamic>> getAgenda(String className, DateTime weekStart) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/agenda/${Uri.encodeComponent(className)}?start=${weekStart.toIso8601String()}'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'schedule': data['schedule']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return {
        'success': true,
        'schedule': []
      };
    }
  }

  static Future<Map<String, dynamic>> saveSchedule({
    required String className,
    required Map<String, dynamic> schedule,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/teacher/schedule'),
        headers: headers,
        body: jsonEncode({
          'className': className,
          'schedule': schedule,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Agenda sauvegardé pour la classe: $className');
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de la sauvegarde'};
      }
    } catch (e) {
      print('❌ Erreur sauvegarde agenda: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getSchedule(String className) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/schedule/${Uri.encodeComponent(className)}'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Agenda chargé pour la classe: $className');
        return {'success': true, 'schedule': data['schedule']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      print('❌ Erreur récupération agenda: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // ==================== ENSEIGNANT - GESTION DES NOTES ====================
  static Future<Map<String, dynamic>> addGrade({
    required String studentId,
    required String subject,
    required double grade,
    required String appreciation,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/teacher/grades'),
        headers: headers,
        body: jsonEncode({
          'studentId': studentId,
          'subject': subject,
          'grade': grade,
          'appreciation': appreciation,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout'};
      }
    } catch (e) {
      return {'success': true, 'message': 'Note ajoutée (mode démo)'};
    }
  }

  // ==================== ENSEIGNANT - GESTION DES ABSENCES ====================
  static Future<Map<String, dynamic>> addAbsence({
    required String studentId,
    required DateTime date,
    required bool justified,
    required String reason,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/teacher/absences'),
        headers: headers,
        body: jsonEncode({
          'studentId': studentId,
          'date': date.toIso8601String(),
          'justified': justified,
          'reason': reason,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout'};
      }
    } catch (e) {
      return {'success': true, 'message': 'Absence ajoutée (mode démo)'};
    }
  }

  // ==================== ADMIN ====================
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard/stats'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'stats': data['stats']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getTeachers() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/teachers'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'teachers': data['teachers']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getTeachersList() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/teachers/list'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'teachers': data['teachers']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> addTeacher({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    List<String> subjects = const [],
    List<String> classes = const [],
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/teachers'),
        headers: headers,
        body: jsonEncode({
          'fullName': fullName,
          'email': email.toLowerCase().trim(),
          'password': password,
          'phoneNumber': phoneNumber ?? '',
          'subjects': subjects,
          'classes': classes,
          'sendEmail': true,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> deleteTeacher(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/teachers/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de la suppression'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getClasses() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/classes'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'classes': data['classes']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getClassesList() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/classes/list'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'classes': data['classes']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> addClass({
    required String level,
    required String group,
    required String className,
    required String teacher,
    int capacity = 30,
    String room = '',
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/classes'),
        headers: headers,
        body: jsonEncode({
          'level': level,
          'group': group,
          'className': className,
          'teacher': teacher,
          'capacity': capacity,
          'room': room,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> deleteClass(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/classes/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de la suppression'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getParents() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/parents'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'parents': data['parents']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> deleteParent(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/parents/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de la suppression'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getStudents() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/students'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'students': data['students']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> deleteStudent(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/students/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de la suppression'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // ==================== DÉCONNEXION ====================
  static Future<void> logout() async {
    await removeToken();
  }
}