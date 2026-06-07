// lib/services/api/student_service.dart
/// Service étudiant pour la gestion des informations et fonctionnalités élèves
/// Gère les cours, emploi du temps, notes, absences, événements, messages et profil

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class StudentService {
  // ==================== INFORMATIONS ÉLÈVE ====================
  
  /// Récupère les informations d'un élève par son email
  static Future<Map<String, dynamic>> getStudentInfo(String email) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/student/info/$email'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'studentId': data['_id'],
          'fullName': data['fullName'],
          'email': data['email'],
          'className': data['className'] ?? 'Non assigné',
          'parentCode': data['parentCode'],
          'isVerified': data['isVerified'] ?? false,
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ==================== COURS ====================
  
  /// Récupère les cours, devoirs et rappels d'un élève par classe
  static Future<Map<String, dynamic>> getStudentLessons(String className) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/student/lessons/${Uri.encodeComponent(className)}'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'lessons': data['lessons'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'lessons': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion', 'lessons': []};
    }
  }

  // ==================== EMPLOI DU TEMPS ====================
  
  /// Récupère l'emploi du temps d'un élève par classe
  static Future<Map<String, dynamic>> getStudentSchedule(String className) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/student/schedule/${Uri.encodeComponent(className)}'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'schedule': data['schedule'] ?? {}};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'schedule': {}};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion', 'schedule': {}};
    }
  }

  // ==================== NOTES ====================
  
  /// Récupère les notes d'examen d'un élève
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
      return {'success': false, 'message': 'Erreur de connexion', 'grades': []};
    }
  }

  // ==================== ABSENCES ====================
  
  /// Récupère les absences d'un élève
  static Future<Map<String, dynamic>> getStudentAbsences(String studentId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/student/absences/$studentId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'absences': data['absences'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'absences': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion', 'absences': []};
    }
  }

  // ==================== ÉVÉNEMENTS ====================
  
  /// Récupère les événements pour un élève
  static Future<Map<String, dynamic>> getStudentEvents(String studentId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/student/events/$studentId'),
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

  /// L'élève répond à un événement
  static Future<Map<String, dynamic>> studentRespondToEvent({
    required String eventId,
    required String studentId,
    required String studentName,
    required String response,
    String? comment,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final responseHttp = await http.post(
        Uri.parse('${ApiClient.baseUrl}/student/events/respond'),
        headers: headers,
        body: jsonEncode({
          'eventId': eventId,
          'studentId': studentId,
          'studentName': studentName,
          'response': response,
          'comment': comment,
        }),
      );
      final data = jsonDecode(responseHttp.body);
      if (responseHttp.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ==================== MESSAGES ====================
  
  /// Récupère les conversations d'un élève
  static Future<Map<String, dynamic>> getStudentConversations(String studentId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/student/conversations/$studentId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'conversations': data['conversations'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'conversations': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion', 'conversations': []};
    }
  }

  /// Envoie un message depuis un élève
  static Future<Map<String, dynamic>> sendStudentMessage({
    required String receiverId,
    required String receiverName,
    required String receiverRole,
    required String message,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/student/send-message'),
        headers: headers,
        body: jsonEncode({
          'receiverId': receiverId,
          'receiverName': receiverName,
          'receiverRole': receiverRole,
          'message': message,
          'attachments': attachments,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ==================== PROFIL ====================
  
  /// Met à jour le profil de l'élève
  static Future<Map<String, dynamic>> updateStudentProfile({
    required String email,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.put(
        Uri.parse('${ApiClient.baseUrl}/student/profile'),
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
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Change le mot de passe de l'élève
  static Future<Map<String, dynamic>> changeStudentPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/student/change-password'),
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
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
}