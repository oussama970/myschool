// lib/services/api/parent_student_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class ParentStudentService {
  // ==================== MÉTHODES EXISTANTES ====================
  
  static Future<Map<String, dynamic>> getStudentDetails(String studentId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/students/$studentId/details'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'student': data['student']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getStudentGradesForParent(String studentId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/students/$studentId/grades-parent'),
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

  static Future<Map<String, dynamic>> getStudentAbsencesForParent(String studentId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/students/$studentId/absences-parent'),
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

  static Future<Map<String, dynamic>> getParentEvents(String studentId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/parent/events/$studentId'),
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

  static Future<Map<String, dynamic>> respondToEvent({
    required String eventId,
    required String studentId,
    required String studentName,
    required String response,
    String? comment,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final responseHttp = await http.post(
        Uri.parse('${ApiClient.baseUrl}/parent/events/respond'),
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
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de la réponse'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  // ==================== NOUVELLES MÉTHODES PARENT ====================

  /// Récupère tous les enfants d'un parent
  static Future<Map<String, dynamic>> getParentChildren(String parentEmail) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/parent/children/$parentEmail'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      print('📡 getParentChildren - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'children': data['children'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'children': []};
    } catch (e) {
      print('❌ Erreur getParentChildren: $e');
      return {'success': false, 'message': 'Erreur de connexion', 'children': []};
    }
  }

  /// Lier un enfant à un parent
  static Future<Map<String, dynamic>> linkChildToParent({
    required String parentCode,
    required String parentId,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/parent/link-child'),
        headers: headers,
        body: jsonEncode({
          'parentCode': parentCode,
          'parentId': parentId,
        }),
      );
      final data = jsonDecode(response.body);
      print('📡 linkChildToParent - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'child': data['child']};
      }
      return {'success': false, 'message': data['message'] ?? 'Code invalide'};
    } catch (e) {
      print('❌ Erreur linkChildToParent: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Récupère les cours/devoirs/rappels d'un enfant
  static Future<Map<String, dynamic>> getChildLessons(String childId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/parent/child/$childId/lessons'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      print('📡 getChildLessons - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'lessons': data['lessons'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'lessons': []};
    } catch (e) {
      print('❌ Erreur getChildLessons: $e');
      return {'success': false, 'message': 'Erreur de connexion', 'lessons': []};
    }
  }

  /// Récupère les notes d'un enfant
  static Future<Map<String, dynamic>> getChildGrades(String childId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/parent/child/$childId/grades'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      print('📡 getChildGrades - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'grades': data['grades'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'grades': []};
    } catch (e) {
      print('❌ Erreur getChildGrades: $e');
      return {'success': false, 'message': 'Erreur de connexion', 'grades': []};
    }
  }

  /// Récupère les notes d'examen d'un enfant
  static Future<Map<String, dynamic>> getChildExamGrades(String childId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/parent/child/$childId/exam-grades'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      print('📡 getChildExamGrades - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'grades': data['grades'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'grades': []};
    } catch (e) {
      print('❌ Erreur getChildExamGrades: $e');
      return {'success': false, 'message': 'Erreur de connexion', 'grades': []};
    }
  }

  /// Récupère les absences d'un enfant
  static Future<Map<String, dynamic>> getChildAbsences(String childId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/parent/child/$childId/absences'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      print('📡 getChildAbsences - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'absences': data['absences'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'absences': []};
    } catch (e) {
      print('❌ Erreur getChildAbsences: $e');
      return {'success': false, 'message': 'Erreur de connexion', 'absences': []};
    }
  }

  /// Récupère les événements pour un enfant
  static Future<Map<String, dynamic>> getChildEvents(String childId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/parent/child/$childId/events'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      print('📡 getChildEvents - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'events': data['events'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'events': []};
    } catch (e) {
      print('❌ Erreur getChildEvents: $e');
      return {'success': false, 'message': 'Erreur de connexion', 'events': []};
    }
  }

  /// Parent répond à un événement
  static Future<Map<String, dynamic>> parentRespondToEvent({
    required String eventId,
    required String studentId,
    required String studentName,
    required String response,
    String? comment,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final responseHttp = await http.post(
        Uri.parse('${ApiClient.baseUrl}/parent/events/respond'),
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
      print('📡 parentRespondToEvent - Status: ${responseHttp.statusCode}');
      if (responseHttp.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      print('❌ Erreur parentRespondToEvent: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Récupère les enseignants de la classe d'un enfant
  static Future<Map<String, dynamic>> getChildTeachers(String childId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/parent/child/$childId/teachers'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      print('📡 getChildTeachers - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'teachers': data['teachers'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'teachers': []};
    } catch (e) {
      print('❌ Erreur getChildTeachers: $e');
      return {'success': false, 'message': 'Erreur de connexion', 'teachers': []};
    }
  }

  /// Récupère les conversations d'un parent
  static Future<Map<String, dynamic>> getParentConversations(String parentId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/parent/conversations/$parentId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      print('📡 getParentConversations - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'conversations': data['conversations'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'conversations': []};
    } catch (e) {
      print('❌ Erreur getParentConversations: $e');
      return {'success': false, 'message': 'Erreur de connexion', 'conversations': []};
    }
  }

  /// Envoyer un message depuis un parent
  static Future<Map<String, dynamic>> sendParentMessage({
    required String receiverId,
    required String receiverName,
    required String receiverRole,
    required String message,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/parent/send-message'),
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
      print('📡 sendParentMessage - Status: ${response.statusCode}');
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      print('❌ Erreur sendParentMessage: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
}