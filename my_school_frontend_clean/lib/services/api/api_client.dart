// lib/services/api/api_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  
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

  static Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      final token = await getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/teacher/upload'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      
      if (response.statusCode == 200) {
        return {'success': true, 'file': data['file']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur upload'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  static Future<Map<String, dynamic>> downloadFile(String filename, String originalName) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/download/$filename'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$originalName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return {'success': true, 'filePath': filePath, 'fileName': originalName};
      }
      return {'success': false, 'message': 'Erreur téléchargement'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  static Future<void> logout() async {
    await removeToken();
  }
}