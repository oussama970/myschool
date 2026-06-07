// lib/services/api/auth_service.dart
/// Service d'authentification pour la gestion des utilisateurs
/// Gère le login, register, vérification email, mot de passe oublié,
/// et la liaison parent-enfant via code parent

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AuthService {
  /// Authentifie un utilisateur et sauvegarde le token JWT
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'password': password,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await ApiClient.saveToken(data['token']);
        }
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Email ou mot de passe incorrect'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// Enregistre un nouvel utilisateur (admin, enseignant, parent, élève)
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/register'),
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
          await ApiClient.saveToken(data['token']);
        }
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur inconnue'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// Vérifie le code email envoyé lors de l'inscription
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'code': code,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Code incorrect'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// Vérifie le code parent pour lier un parent à son enfant
  static Future<Map<String, dynamic>> verifyParentCode({
    required String parentCode,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/verify-parent-code'),
        headers: headers,
        body: jsonEncode({'parentCode': parentCode}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Code invalide'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// Récupère l'enfant lié à un parent
  static Future<Map<String, dynamic>> getLinkedChild(String parentEmail) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/auth/linked-child/${parentEmail.toLowerCase().trim()}'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'child': data['child']};
      }
      return {'success': false, 'message': data['message'] ?? 'Aucun enfant lié'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// Envoie un email de réinitialisation de mot de passe
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.toLowerCase().trim()}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'], 'email': data['email']};
      }
      return {'success': false, 'message': data['message'] ?? 'Email non trouvé'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// Réinitialise le mot de passe avec le code de vérification
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/auth/reset-password'),
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
      }
      return {'success': false, 'message': data['message'] ?? 'Code invalide'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// Récupère les informations d'un enfant par email
  static Future<Map<String, dynamic>> getChildInfo(String email) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/auth/child/${email.toLowerCase().trim()}'),
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
      }
      return {'success': false, 'message': data['message'] ?? 'Enfant non trouvé'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }
}