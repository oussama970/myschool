import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  // === GESTION DU TOKEN SIMPLIFIÉE ===
  
  /// Sauvegarder le token
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      print('✅ TOKEN SAUVEGARDÉ: ${token.substring(0, 15)}...');
      
      // Vérification immédiate
      final saved = prefs.getString('token');
      print('🔍 VÉRIFICATION: token présent = ${saved != null}');
    } catch (e) {
      print('❌ Erreur saveToken: $e');
    }
  }

  /// Récupérer le token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print('🔑 TOKEN RÉCUPÉRÉ: ${token != null}');
      if (token != null) {
        print('📝 Début du token: ${token.substring(0, 15)}...');
      }
      return token;
    } catch (e) {
      print('❌ Erreur getToken: $e');
      return null;
    }
  }

  /// Supprimer le token
  static Future<void> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      print('🔓 TOKEN SUPPRIMÉ');
    } catch (e) {
      print('❌ Erreur removeToken: $e');
    }
  }

  /// Obtenir les headers avec le token (VERSION ULTRA-SIMPLE)
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    
    // HEADERS DE BASE
    final headers = {
      'Content-Type': 'application/json',
    };
    
    // AJOUTER LE TOKEN SI DISPONIBLE
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      print('📤 HEADER Authorization AJOUTÉ: Bearer ${token.substring(0, 15)}...');
    } else {
      print('⚠️ HEADER Authorization NON AJOUTÉ (token null)');
    }
    
    print('📤 HEADERS COMPLETS: $headers');
    return headers;
  }

  // === AUTHENTIFICATION ===

  /// 1. INSCRIPTION
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      print('📤 INSCRIPTION - Email: $email, Rôle: $role');
      
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
      print('📥 RÉPONSE register: ${response.statusCode}');

      if (response.statusCode == 201) {
        // SAUVEGARDER LE TOKEN
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur inconnue'};
      }
    } catch (e) {
      print('❌ Erreur register: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// 2. VÉRIFICATION EMAIL ÉLÈVE
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      print('📤 Vérification email - Email: $email, Code: $code');
      
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
      print('❌ Erreur verifyEmail: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// 3. CONNEXION
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('📤 CONNEXION - Email: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      print('📥 RÉPONSE login: ${response.statusCode}');

      if (response.statusCode == 200) {
        // SAUVEGARDER LE TOKEN
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Email ou mot de passe incorrect'};
      }
    } catch (e) {
      print('❌ Erreur login: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// 4. VÉRIFICATION CODE PARENT (AVEC TOKEN) - VERSION ROBUSTE
  static Future<Map<String, dynamic>> verifyParentCode({
    required String parentCode,
  }) async {
    try {
      print('📤 VÉRIFICATION CODE PARENT - Code: $parentCode');
      
      // RÉCUPÉRER LE TOKEN DIRECTEMENT
      final token = await getToken();
      print('🔑 TOKEN RÉCUPÉRÉ: ${token != null}');
      
      // CONSTRUIRE LES HEADERS MANUELLEMENT
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('📤 AUTHORIZATION AJOUTÉ: Bearer ${token.substring(0, 15)}...');
      } else {
        print('❌ ERREUR: Token est null!');
      }
      
      print('📤 HEADERS FINAUX: $headers');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-parent-code'),
        headers: headers,
        body: jsonEncode({'parentCode': parentCode}),
      );

      print('📥 STATUT: ${response.statusCode}');
      final data = jsonDecode(response.body);
      print('📥 RÉPONSE: $data');

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        await removeToken();
        return {'success': false, 'message': 'Session expirée. Veuillez vous reconnecter.'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Code invalide'};
      }
    } catch (e) {
      print('❌ ERREUR verifyParentCode: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// 5. RÉCUPÉRER L'ENFANT LIÉ À UN PARENT
  static Future<Map<String, dynamic>> getLinkedChild(String parentEmail) async {
    try {
      print('📤 Récupération enfant lié - Parent: $parentEmail');
      
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
      print('❌ Erreur getLinkedChild: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// 6. RÉCUPÉRER LES INFORMATIONS D'UN ENFANT
  static Future<Map<String, dynamic>> getChildInfo(String email) async {
    try {
      print('📤 Récupération info enfant - Email: $email');
      
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
      print('❌ Erreur getChildInfo: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// 7. MOT DE PASSE OUBLIÉ
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print('📤 Mot de passe oublié - Email: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.toLowerCase().trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'message': data['message'] ?? 'Code envoyé',
          'email': data['email'] ?? email
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Email non trouvé'};
      }
    } catch (e) {
      print('❌ Erreur forgotPassword: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// 8. RÉINITIALISER MOT DE PASSE
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      print('📤 Réinitialisation mot de passe - Email: $email, Code: $code');
      
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
        return {'success': true, 'message': data['message'] ?? 'Mot de passe réinitialisé'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Code invalide'};
      }
    } catch (e) {
      print('❌ Erreur resetPassword: $e');
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// 9. DÉCONNEXION
  static Future<void> logout() async {
    await removeToken();
  }
  
  /// 10. TEST - Vider toutes les données
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ Toutes les données effacées');
    } catch (e) {
      print('❌ Erreur effacement: $e');
    }
  }
}