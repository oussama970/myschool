// lib/models/event_model.dart
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
  final DateTime? responseDeadline; // ✅ AJOUT

  EventModel({
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
    this.responseDeadline, // ✅ AJOUT
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    List<EventResponse> responses = [];
    
    if (json['studentResponses'] != null) {
      final responsesList = json['studentResponses'] as List;
      for (var resp in responsesList) {
        responses.add(EventResponse.fromJson(resp));
      }
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
      responseDeadline: responseDeadline, // ✅ AJOUT
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'status': status,
    'teacherId': teacherId,
    'teacherName': teacherName,
    'className': className,
    'studentResponses': studentResponses.map((e) => e.toJson()).toList(),
    'responseDeadline': responseDeadline?.toIso8601String(), // ✅ AJOUT
  };
  
  // Getter pour compter les réponses
  int get acceptedCount => studentResponses.where((r) => r.response == 'accepted').length;
  int get rejectedCount => studentResponses.where((r) => r.response == 'rejected').length;
  int get pendingCount => studentResponses.where((r) => r.response == 'pending').length;
}

class EventResponse {
  final String studentId;
  final String studentName;
  final String response;
  final String? comment;
  final DateTime respondedAt;

  EventResponse({
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