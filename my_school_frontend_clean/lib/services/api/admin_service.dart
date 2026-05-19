// lib/services/api/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AdminService {
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/admin/dashboard/stats'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'stats': data['stats']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getTeachers() async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/admin/teachers'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'teachers': data['teachers'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getTeachersList() async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/admin/teachers/list'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'teachers': data['teachers'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
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
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/admin/teachers'),
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
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> deleteTeacher(String id) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiClient.baseUrl}/admin/teachers/$id'),
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

  static Future<Map<String, dynamic>> getClasses() async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/admin/classes'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'classes': data['classes'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> getClassesList() async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/admin/classes/list'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'classes': data['classes'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
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
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/admin/classes'),
        headers: headers,
        body: jsonEncode({
          'level': level,
          'group': group,
          'name': className,
          'teacher': teacher,
          'capacity': capacity,
          'room': room,
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

  static Future<Map<String, dynamic>> deleteClass(String id) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiClient.baseUrl}/admin/classes/$id'),
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

  static Future<Map<String, dynamic>> getParents() async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/admin/parents'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'parents': data['parents'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'parents': []};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur', 'parents': []};
    }
  }

  static Future<Map<String, dynamic>> deleteParent(String id) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiClient.baseUrl}/admin/parents/$id'),
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

  static Future<Map<String, dynamic>> getStudents() async {
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
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> deleteStudent(String id) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiClient.baseUrl}/admin/students/$id'),
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

  static Future<Map<String, dynamic>> getAdminProfile(String email) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/admin/profile/$email'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'fullName': data['fullName'],
          'email': data['email'],
          'phoneNumber': data['phoneNumber'] ?? '',
          'createdAt': data['createdAt'],
          'lastLogin': data['lastLogin'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  static Future<Map<String, dynamic>> updateAdminProfile({
    required String email,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.put(
        Uri.parse('${ApiClient.baseUrl}/admin/profile'),
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

  static Future<Map<String, dynamic>> changeAdminPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/admin/change-password'),
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