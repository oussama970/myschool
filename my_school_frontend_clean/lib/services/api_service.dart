// lib/services/api_service.dart
/// POINT D'ENTRÉE UNIQUE - Service API centralisé
/// Exporte et agrège toutes les fonctionnalités des différents services
/// (authentification, administration, enseignant, parent, élève, messages)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'api/api_client.dart';
import 'api/auth_service.dart';
import 'api/admin_service.dart';
import 'api/teacher_service.dart';
import 'api/parent_student_service.dart';
import 'api/message_service.dart';
import 'api/student_service.dart';

// Exports des services
export 'api/api_client.dart';
export 'api/auth_service.dart';
export 'api/admin_service.dart';
export 'api/teacher_service.dart';
export 'api/parent_student_service.dart';
export 'api/message_service.dart';
export 'api/student_service.dart';

class ApiService {
  // ==================== TOKEN ====================
  static Future<String?> getToken() => ApiClient.getToken();
  static Future<void> saveToken(String token) => ApiClient.saveToken(token);
  static Future<void> removeToken() => ApiClient.removeToken();

  // ==================== AUTHENTIFICATION ====================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) => AuthService.login(email: email, password: password);

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) => AuthService.register(
    fullName: fullName,
    email: email,
    password: password,
    role: role,
  );

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) => AuthService.verifyEmail(email: email, code: code);

  static Future<Map<String, dynamic>> verifyParentCode({
    required String parentCode,
  }) => AuthService.verifyParentCode(parentCode: parentCode);

  static Future<Map<String, dynamic>> getLinkedChild(String parentEmail) =>
      AuthService.getLinkedChild(parentEmail);

  static Future<Map<String, dynamic>> forgotPassword(String email) =>
      AuthService.forgotPassword(email);

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => AuthService.resetPassword(
    email: email,
    code: code,
    newPassword: newPassword,
  );

  static Future<Map<String, dynamic>> getChildInfo(String email) =>
      AuthService.getChildInfo(email);

  // ==================== ADMINISTRATION ====================
  static Future<Map<String, dynamic>> getDashboardStats() =>
      AdminService.getDashboardStats();

  static Future<Map<String, dynamic>> getTeachers() =>
      AdminService.getTeachers();

  static Future<Map<String, dynamic>> getTeachersList() =>
      AdminService.getTeachersList();

  static Future<Map<String, dynamic>> addTeacher({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    List<String> subjects = const [],
    List<String> classes = const [],
  }) => AdminService.addTeacher(
    fullName: fullName,
    email: email,
    password: password,
    phoneNumber: phoneNumber,
    subjects: subjects,
    classes: classes,
  );

  static Future<Map<String, dynamic>> deleteTeacher(String id) =>
      AdminService.deleteTeacher(id);

  static Future<Map<String, dynamic>> getClasses() =>
      AdminService.getClasses();

  static Future<Map<String, dynamic>> getClassesList() =>
      AdminService.getClassesList();

  static Future<Map<String, dynamic>> addClass({
    required String level,
    required String group,
    required String className,
    required String teacher,
    int capacity = 30,
    String room = '',
  }) => AdminService.addClass(
    level: level,
    group: group,
    className: className,
    teacher: teacher,
    capacity: capacity,
    room: room,
  );

  static Future<Map<String, dynamic>> deleteClass(String id) =>
      AdminService.deleteClass(id);

  static Future<Map<String, dynamic>> getParents() =>
      AdminService.getParents();

  static Future<Map<String, dynamic>> deleteParent(String id) =>
      AdminService.deleteParent(id);

  static Future<Map<String, dynamic>> getStudents() =>
      AdminService.getStudents();

  static Future<Map<String, dynamic>> deleteStudent(String id) =>
      AdminService.deleteStudent(id);

  static Future<Map<String, dynamic>> getAdminProfile(String email) =>
      AdminService.getAdminProfile(email);

  static Future<Map<String, dynamic>> updateAdminProfile({
    required String email,
    required String fullName,
    required String phoneNumber,
  }) => AdminService.updateAdminProfile(
    email: email,
    fullName: fullName,
    phoneNumber: phoneNumber,
  );

  static Future<Map<String, dynamic>> changeAdminPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) => AdminService.changeAdminPassword(
    email: email,
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  // ==================== ENSEIGNANT ====================
  static Future<Map<String, dynamic>> getTeacherInfo(String email) =>
      TeacherService.getTeacherInfo(email);

  static Future<Map<String, dynamic>> getTeacherClasses() =>
      TeacherService.getTeacherClasses();

  static Future<Map<String, dynamic>> getTeacherNotifications(String email) =>
      TeacherService.getTeacherNotifications(email);

  static Future<Map<String, dynamic>> getStudentsByClass(String className) =>
      TeacherService.getStudentsByClass(className);

  static Future<Map<String, dynamic>> getStudentLinkedParents(String studentId) =>
      TeacherService.getStudentLinkedParents(studentId);

  static Future<Map<String, dynamic>> getAllStudents() =>
      TeacherService.getAllStudents();

  static Future<Map<String, dynamic>> addStudentsToClass({
    required String className,
    required List<String> studentIds,
  }) => TeacherService.addStudentsToClass(className: className, studentIds: studentIds);

  static Future<Map<String, dynamic>> removeStudentFromClass({
    required String studentId,
    required String className,
  }) => TeacherService.removeStudentFromClass(studentId: studentId, className: className);

  static Future<Map<String, dynamic>> getLessons(String className) =>
      TeacherService.getLessons(className);

  static Future<Map<String, dynamic>> addLesson({
    required String title,
    required String subject,
    required String description,
    required String type,
    required String className,
    String? deadline,
    List<Map<String, dynamic>> files = const [],
  }) => TeacherService.addLesson(
    title: title,
    subject: subject,
    description: description,
    type: type,
    className: className,
    deadline: deadline,
    files: files,
  );

  static Future<Map<String, dynamic>> updateLesson({
    required String id,
    required String title,
    required String subject,
    required String description,
    required String type,
    String? deadline,
    List<Map<String, dynamic>> files = const [],
  }) => TeacherService.updateLesson(
    id: id,
    title: title,
    subject: subject,
    description: description,
    type: type,
    deadline: deadline,
    files: files,
  );

  static Future<Map<String, dynamic>> deleteLesson(String id) =>
      TeacherService.deleteLesson(id);

  static Future<Map<String, dynamic>> getTeacherEvents({
    required String className,
    required String teacherId,
  }) => TeacherService.getTeacherEvents(className: className, teacherId: teacherId);

  static Future<Map<String, dynamic>> addEvent({
    required String title,
    required String description,
    required DateTime date,
    required String teacherId,
    required String teacherName,
    required String className,
    DateTime? responseDeadline,
  }) => TeacherService.addEvent(
    title: title,
    description: description,
    date: date,
    teacherId: teacherId,
    teacherName: teacherName,
    className: className,
    responseDeadline: responseDeadline,
  );

  static Future<Map<String, dynamic>> deleteEvent(String eventId) =>
      TeacherService.deleteEvent(eventId);

  static Future<Map<String, dynamic>> getAgendaEvents({
    required String className,
    required String teacherId,
  }) => TeacherService.getAgendaEvents(className: className, teacherId: teacherId);

  static Future<Map<String, dynamic>> addAgendaEvent({
    required String className,
    required String subject,
    required String type,
    required String day,
    required String timeSlot,
    required DateTime date,
    required String teacherId,
    required String teacherName,
  }) => TeacherService.addAgendaEvent(
    className: className,
    subject: subject,
    type: type,
    day: day,
    timeSlot: timeSlot,
    date: date,
    teacherId: teacherId,
    teacherName: teacherName,
  );

  static Future<Map<String, dynamic>> deleteAgendaEvent(String eventId) =>
      TeacherService.deleteAgendaEvent(eventId);

  static Future<Map<String, dynamic>> getAllExamsByClass(String className, String studentId) =>
      TeacherService.getAllExamsByClass(className, studentId);

  static Future<Map<String, dynamic>> addExamGrade({
    required String examId,
    required String studentId,
    required String studentName,
    required String subject,
    required double grade,
    required String appreciation,
    String? photoUrl,
    required String teacherName,
  }) => TeacherService.addExamGrade(
    examId: examId,
    studentId: studentId,
    studentName: studentName,
    subject: subject,
    grade: grade,
    appreciation: appreciation,
    photoUrl: photoUrl,
    teacherName: teacherName,
  );

  static Future<Map<String, dynamic>> getExamGrades(String examId) =>
      TeacherService.getExamGrades(examId);

  static Future<Map<String, dynamic>> getStudentExamGrades(String studentId) =>
      TeacherService.getStudentExamGrades(studentId);

  static Future<Map<String, dynamic>> getStudentGrades(String studentId) =>
      TeacherService.getStudentGrades(studentId);

  static Future<Map<String, dynamic>> getStudentAbsences(String studentId) =>
      TeacherService.getStudentAbsences(studentId);

  static Future<Map<String, dynamic>> addAbsence({
    required String studentId,
    required DateTime date,
    required bool justified,
    required String reason,
    required String subject,
  }) => TeacherService.addAbsence(
    studentId: studentId,
    date: date,
    justified: justified,
    reason: reason,
    subject: subject,
  );

  static Future<Map<String, dynamic>> addGrade({
    required String studentId,
    required String subject,
    required double grade,
    required String appreciation,
  }) => TeacherService.addGrade(
    studentId: studentId,
    subject: subject,
    grade: grade,
    appreciation: appreciation,
  );

  static Future<Map<String, dynamic>> deleteGrade(String gradeId) =>
      TeacherService.deleteGrade(gradeId);

  static Future<Map<String, dynamic>> saveSchedule({
    required String className,
    required Map<String, dynamic> schedule,
  }) => TeacherService.saveSchedule(className: className, schedule: schedule);

  static Future<Map<String, dynamic>> getSchedule(String className) =>
      TeacherService.getSchedule(className);

  static Future<Map<String, dynamic>> getTeacherSchedule(String teacherEmail, String className) =>
      TeacherService.getTeacherSchedule(teacherEmail, className);

  static Future<Map<String, dynamic>> getAllTeacherSchedules(String teacherEmail) =>
      TeacherService.getAllTeacherSchedules(teacherEmail);

  static Future<Map<String, dynamic>> updateTeacherProfile({
    required String email,
    required String fullName,
    required String phoneNumber,
  }) => TeacherService.updateTeacherProfile(
    email: email,
    fullName: fullName,
    phoneNumber: phoneNumber,
  );

  static Future<Map<String, dynamic>> changeTeacherPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) => TeacherService.changeTeacherPassword(
    email: email,
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  // ==================== PARENT/ÉLÈVE (HÉRITÉ) ====================
  static Future<Map<String, dynamic>> getStudentDetails(String studentId) =>
      ParentStudentService.getStudentDetails(studentId);

  static Future<Map<String, dynamic>> getStudentGradesForParent(String studentId) =>
      ParentStudentService.getStudentGradesForParent(studentId);

  static Future<Map<String, dynamic>> getStudentAbsencesForParent(String studentId) =>
      ParentStudentService.getStudentAbsencesForParent(studentId);

  static Future<Map<String, dynamic>> getParentEvents(String studentId) =>
      ParentStudentService.getParentEvents(studentId);

  static Future<Map<String, dynamic>> respondToEvent({
    required String eventId,
    required String studentId,
    required String studentName,
    required String response,
    String? comment,
  }) => ParentStudentService.respondToEvent(
    eventId: eventId,
    studentId: studentId,
    studentName: studentName,
    response: response,
    comment: comment,
  );

  // ==================== MÉTHODES PARENT ====================
  static Future<Map<String, dynamic>> getParentChildren(String parentEmail) =>
      ParentStudentService.getParentChildren(parentEmail);

  static Future<Map<String, dynamic>> linkChildToParent({
    required String parentCode,
    required String parentId,
  }) => ParentStudentService.linkChildToParent(
    parentCode: parentCode,
    parentId: parentId,
  );

  static Future<Map<String, dynamic>> getChildLessons(String childId) =>
      ParentStudentService.getChildLessons(childId);

  static Future<Map<String, dynamic>> getChildGrades(String childId) =>
      ParentStudentService.getChildGrades(childId);

  static Future<Map<String, dynamic>> getChildExamGrades(String childId) =>
      ParentStudentService.getChildExamGrades(childId);

  static Future<Map<String, dynamic>> getChildAbsences(String childId) =>
      ParentStudentService.getChildAbsences(childId);

  static Future<Map<String, dynamic>> getChildEvents(String childId) =>
      ParentStudentService.getChildEvents(childId);

  static Future<Map<String, dynamic>> parentRespondToEvent({
    required String eventId,
    required String studentId,
    required String studentName,
    required String response,
    String? comment,
  }) => ParentStudentService.parentRespondToEvent(
    eventId: eventId,
    studentId: studentId,
    studentName: studentName,
    response: response,
    comment: comment,
  );

  static Future<Map<String, dynamic>> getChildTeachers(String childId) =>
      ParentStudentService.getChildTeachers(childId);

  static Future<Map<String, dynamic>> getParentConversations(String parentId) =>
      ParentStudentService.getParentConversations(parentId);

  static Future<Map<String, dynamic>> sendParentMessage({
    required String receiverId,
    required String receiverName,
    required String receiverRole,
    required String message,
    List<Map<String, dynamic>> attachments = const [],
  }) => ParentStudentService.sendParentMessage(
    receiverId: receiverId,
    receiverName: receiverName,
    receiverRole: receiverRole,
    message: message,
    attachments: attachments,
  );

  // ==================== MESSAGES ====================
  static Future<Map<String, dynamic>> getConversations() =>
      MessageService.getConversations();

  static Future<Map<String, dynamic>> getMessages(String contactId) =>
      MessageService.getMessages(contactId);

  static Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String receiverName,
    required String receiverRole,
    required String message,
    List<Map<String, dynamic>> attachments = const [],
  }) => MessageService.sendMessage(
    receiverId: receiverId,
    receiverName: receiverName,
    receiverRole: receiverRole,
    message: message,
    attachments: attachments,
  );

  static Future<Map<String, dynamic>> markAsRead(String messageId) =>
      MessageService.markAsRead(messageId);

  static Future<Map<String, dynamic>> getContacts() =>
      MessageService.getContacts();

  // ==================== FICHIERS ====================
  static Future<Map<String, dynamic>> uploadFile(File file) =>
      ApiClient.uploadFile(file);

  static Future<Map<String, dynamic>> downloadFile(String filename, String originalName) =>
      ApiClient.downloadFile(filename, originalName);

  static Future<void> logout() => ApiClient.logout();

  // ==================== ÉLÈVE ====================
  static Future<Map<String, dynamic>> getStudentInfo(String email) =>
      StudentService.getStudentInfo(email);

  static Future<Map<String, dynamic>> getStudentLessons(String className) =>
      StudentService.getStudentLessons(className);

  static Future<Map<String, dynamic>> getStudentSchedule(String className) =>
      StudentService.getStudentSchedule(className);

  static Future<Map<String, dynamic>> getStudentEvents(String studentId) =>
      StudentService.getStudentEvents(studentId);

  static Future<Map<String, dynamic>> studentRespondToEvent({
    required String eventId,
    required String studentId,
    required String studentName,
    required String response,
    String? comment,
  }) => StudentService.studentRespondToEvent(
    eventId: eventId,
    studentId: studentId,
    studentName: studentName,
    response: response,
    comment: comment,
  );

  static Future<Map<String, dynamic>> getStudentConversations(String studentId) =>
      StudentService.getStudentConversations(studentId);

  static Future<Map<String, dynamic>> sendStudentMessage({
    required String receiverId,
    required String receiverName,
    required String receiverRole,
    required String message,
    List<Map<String, dynamic>> attachments = const [],
  }) => StudentService.sendStudentMessage(
    receiverId: receiverId,
    receiverName: receiverName,
    receiverRole: receiverRole,
    message: message,
    attachments: attachments,
  );

  static Future<Map<String, dynamic>> updateStudentProfile({
    required String email,
    required String fullName,
    required String phoneNumber,
  }) => StudentService.updateStudentProfile(
    email: email,
    fullName: fullName,
    phoneNumber: phoneNumber,
  );

  static Future<Map<String, dynamic>> changeStudentPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) => StudentService.changeStudentPassword(
    email: email,
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  // ==================== SOUMISSIONS DE DEVOIRS ====================

  /// Élève: Soumettre un devoir
  static Future<Map<String, dynamic>> submitHomework({
    required String lessonId,
    required String content,
    required List<Map<String, dynamic>> attachments,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/student/submit-homework'),
        headers: headers,
        body: jsonEncode({
          'lessonId': lessonId,
          'content': content,
          'attachments': attachments,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'submission': data['submission']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de la soumission'};
    } catch (e) {
      print('❌ Erreur submitHomework: $e');
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  /// Élève: Récupérer toutes ses soumissions
  static Future<Map<String, dynamic>> getMySubmissions() async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/student/my-submissions'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'submissions': data['submissions'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'submissions': []};
    } catch (e) {
      print('❌ Erreur getMySubmissions: $e');
      return {'success': false, 'message': 'Erreur de connexion', 'submissions': []};
    }
  }

  /// Élève: Récupérer sa soumission pour un devoir spécifique
  static Future<Map<String, dynamic>> getStudentSubmissionForLesson(String lessonId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/student/homework-submission/$lessonId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'submission': data['submission']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'submission': null};
    } catch (e) {
      print('❌ Erreur getStudentSubmissionForLesson: $e');
      return {'success': false, 'message': 'Erreur de connexion', 'submission': null};
    }
  }

  /// Enseignant: Récupérer toutes les soumissions pour un devoir
  static Future<Map<String, dynamic>> getSubmissionsByLesson(String lessonId) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/teacher/homework-submissions/$lessonId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'submissions': data['submissions'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur', 'submissions': []};
    } catch (e) {
      print('❌ Erreur getSubmissionsByLesson: $e');
      return {'success': false, 'message': 'Erreur de connexion', 'submissions': []};
    }
  }

  /// Enseignant: Noter une soumission
  static Future<Map<String, dynamic>> gradeSubmission({
    required String submissionId,
    required double grade,
    required String feedback,
  }) async {
    try {
      final headers = await ApiClient.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/teacher/homework-submissions/$submissionId/grade'),
        headers: headers,
        body: jsonEncode({
          'grade': grade,
          'feedback': feedback,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'submission': data['submission']};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de la notation'};
    } catch (e) {
      print('❌ Erreur gradeSubmission: $e');
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }
}