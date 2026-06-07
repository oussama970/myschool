// lib/services/api/api_client.dart
/// Client HTTP centralisé pour les appels API
/// Gère la configuration réseau (IP du serveur), les tokens JWT,
/// l'upload/download de fichiers et la déconnexion

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ApiClient {
  // ✅ IP de votre ordinateur (fonctionne sur émulateur ET téléphone)
  static const String ip = '10.224.96.72';  // ← REMPLACEZ PAR VOTRE IP
  static const String baseUrl = 'http://$ip:5000/api';
  
  /// Sauvegarde le token JWT dans SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    print('✅ Token sauvegardé');
  }

  /// Récupère le token JWT depuis SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Supprime le token JWT (déconnexion)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    print('🔓 Token supprimé');
  }

  /// Construit les headers pour les requêtes HTTP (Authorization + Content-Type)
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  /// Upload d'un fichier vers le serveur (multipart/form-data)
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

  /// Télécharge un fichier depuis le serveur et le sauvegarde localement
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

  /// Déconnexion: supprime le token
  static Future<void> logout() async {
    await removeToken();
  }
}