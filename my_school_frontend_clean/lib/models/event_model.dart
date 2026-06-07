// lib/models/event_model.dart

/// Modèle représentant un événement scolaire
class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String status;
  final String teacherId;
  final String teacherName;
  final String className;
  final List<EventResponse> studentResponses;
  final DateTime createdAt;
  final DateTime? responseDeadline;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.teacherId,
    required this.teacherName,
    required this.className,
    required this.studentResponses,
    required this.createdAt,
    this.responseDeadline,
  });

  /// Convertit JSON en EventModel
  factory EventModel.fromJson(Map<String, dynamic> json) {
    List<EventResponse> responses = [];
    
    if (json['studentResponses'] != null) {
      final responsesList = json['studentResponses'] as List;
      responses = responsesList.map((r) => EventResponse.fromJson(r)).toList();
    }

    DateTime? responseDeadline;
    if (json['responseDeadline'] != null) {
      responseDeadline = DateTime.parse(json['responseDeadline']);
    }

    return EventModel(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? 'Sans titre',
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
      status: json['status'] ?? 'pending',
      teacherId: json['teacherId'],
      teacherName: json['teacherName'] ?? '',
      className: json['className'] ?? '',
      studentResponses: responses,
      createdAt: DateTime.parse(json['createdAt']),
      responseDeadline: responseDeadline,
    );
  }

  /// Convertit EventModel en JSON
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'status': status,
    'teacherId': teacherId,
    'teacherName': teacherName,
    'className': className,
    'studentResponses': studentResponses.map((e) => e.toJson()).toList(),
    'responseDeadline': responseDeadline?.toIso8601String(),
  };
  
  /// Nombre de réponses acceptées
  int get acceptedCount => studentResponses.where((r) => r.response == 'accepted').length;
  
  /// Nombre de réponses refusées
  int get rejectedCount => studentResponses.where((r) => r.response == 'rejected').length;
  
  /// Nombre de réponses en attente
  int get pendingCount => studentResponses.where((r) => r.response == 'pending').length;
}

/// Modèle représentant la réponse d'un élève à un événement
class EventResponse {
  final String studentId;
  final String studentName;
  final String response;
  final String? comment;
  final DateTime respondedAt;

  const EventResponse({
    required this.studentId,
    required this.studentName,
    required this.response,
    this.comment,
    required this.respondedAt,
  });

  factory EventResponse.fromJson(Map<String, dynamic> json) => EventResponse(
    studentId: json['studentId'],
    studentName: json['studentName'],
    response: json['response'] ?? 'pending',
    comment: json['comment'],
    respondedAt: DateTime.parse(json['respondedAt']),
  );

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'response': response,
    'comment': comment,
    'respondedAt': respondedAt.toIso8601String(),
  };
}