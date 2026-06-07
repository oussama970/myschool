// lib/services/api/message_service.dart
/// Service de messagerie pour la gestion des conversations
/// Permet de récupérer les conversations, les messages, envoyer des messages,
/// marquer comme lus et obtenir les contacts disponibles

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class MessageService {
  /// Récupère la liste des conversations de l'utilisateur connecté
  static Future<Map<String, dynamic>> getConversations() async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/messages/conversations'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'conversations': data['conversations'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// Récupère tous les messages d'une conversation avec un contact
  static Future<Map<String, dynamic>> getMessages(String contactId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/messages/messages/$contactId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'messages': data['messages'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// Envoie un message à un contact (avec pièces jointes optionnelles)
  static Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String receiverName,
    required String receiverRole,
    required String message,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/messages/send'),
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
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'envoi'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }

  /// Marque un message comme lu
  static Future<Map<String, dynamic>> markAsRead(String messageId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.put(
        Uri.parse('${ApiClient.baseUrl}/messages/read/$messageId'),
        headers: headers,
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

  /// Récupère la liste des contacts disponibles (enseignants, parents, élèves)
  static Future<Map<String, dynamic>> getContacts() async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/messages/contacts'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'contacts': data['contacts'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion au serveur'};
    }
  }
}