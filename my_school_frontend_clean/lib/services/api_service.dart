// lib/services/api_service.dart
// POINT D'ENTRÉE UNIQUE - Exporte toutes les fonctionnalités

import 'dart:io';
import 'api/api_client.dart';
import 'api/auth_service.dart';
import 'api/admin_service.dart';
import 'api/teacher_service.dart';
import 'api/parent_student_service.dart';
import 'api/message_service.dart';
import 'api/student_service.dart';

// Exports
export 'api/api_client.dart';
export 'api/auth_service.dart';
export 'api/admin_service.dart';
export 'api/teacher_service.dart';
export 'api/parent_student_service.dart';
export 'api/message_service.dart';
export 'api/student_service.dart';

class ApiService {
  // ==================== TOKEN ====================
  static Future<String?> getToken() {
    return ApiClient.getToken();
  }

  static Future<void> saveToken(String token) {
    return ApiClient.saveToken(token);
  }

  static Future<void> removeToken() {
    return ApiClient.removeToken();
  }

  // ==================== AUTH ====================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return AuthService.login(email: email, password: password);
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) {
    return AuthService.register(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
    );
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) {
    return AuthService.verifyEmail(email: email, code: code);
  }

  static Future<Map<String, dynamic>> verifyParentCode({
    required String parentCode,
  }) {
    return AuthService.verifyParentCode(parentCode: parentCode);
  }

  static Future<Map<String, dynamic>> getLinkedChild(String parentEmail) {
    return AuthService.getLinkedChild(parentEmail);
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) {
    return AuthService.forgotPassword(email);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return AuthService.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  static Future<Map<String, dynamic>> getChildInfo(String email) {
    return AuthService.getChildInfo(email);
  }

  // ==================== ADMIN ====================
  static Future<Map<String, dynamic>> getDashboardStats() {
    return AdminService.getDashboardStats();
  }

  static Future<Map<String, dynamic>> getTeachers() {
    return AdminService.getTeachers();
  }

  static Future<Map<String, dynamic>> getTeachersList() {
    return AdminService.getTeachersList();
  }

  static Future<Map<String, dynamic>> addTeacher({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    List<String> subjects = const [],
    List<String> classes = const [],
  }) {
    return AdminService.addTeacher(
      fullName: fullName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      subjects: subjects,
      classes: classes,
    );
  }

  static Future<Map<String, dynamic>> deleteTeacher(String id) {
    return AdminService.deleteTeacher(id);
  }

  static Future<Map<String, dynamic>> getClasses() {
    return AdminService.getClasses();
  }

  static Future<Map<String, dynamic>> getClassesList() {
    return AdminService.getClassesList();
  }

  static Future<Map<String, dynamic>> addClass({
    required String level,
    required String group,
    required String className,
    required String teacher,
    int capacity = 30,
    String room = '',
  }) {
    return AdminService.addClass(
      level: level,
      group: group,
      className: className,
      teacher: teacher,
      capacity: capacity,
      room: room,
    );
  }

  static Future<Map<String, dynamic>> deleteClass(String id) {
    return AdminService.deleteClass(id);
  }

  static Future<Map<String, dynamic>> getParents() {
    return AdminService.getParents();
  }

  static Future<Map<String, dynamic>> deleteParent(String id) {
    return AdminService.deleteParent(id);
  }

  static Future<Map<String, dynamic>> getStudents() {
    return AdminService.getStudents();
  }

  static Future<Map<String, dynamic>> deleteStudent(String id) {
    return AdminService.deleteStudent(id);
  }

  static Future<Map<String, dynamic>> getAdminProfile(String email) {
    return AdminService.getAdminProfile(email);
  }

  static Future<Map<String, dynamic>> updateAdminProfile({
    required String email,
    required String fullName,
    required String phoneNumber,
  }) {
    return AdminService.updateAdminProfile(
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }

  static Future<Map<String, dynamic>> changeAdminPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) {
    return AdminService.changeAdminPassword(
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  // ==================== TEACHER ====================
  static Future<Map<String, dynamic>> getTeacherInfo(String email) {
    return TeacherService.getTeacherInfo(email);
  }

  static Future<Map<String, dynamic>> getTeacherClasses() {
    return TeacherService.getTeacherClasses();
  }

  static Future<Map<String, dynamic>> getTeacherNotifications(String email) {
    return TeacherService.getTeacherNotifications(email);
  }

  static Future<Map<String, dynamic>> getStudentsByClass(String className) {
    return TeacherService.getStudentsByClass(className);
  }

  static Future<Map<String, dynamic>> getStudentLinkedParents(String studentId) {
    return TeacherService.getStudentLinkedParents(studentId);
  }

  static Future<Map<String, dynamic>> getAllStudents() {
    return TeacherService.getAllStudents();
  }

  static Future<Map<String, dynamic>> addStudentsToClass({
    required String className,
    required List<String> studentIds,
  }) {
    return TeacherService.addStudentsToClass(className: className, studentIds: studentIds);
  }

  static Future<Map<String, dynamic>> removeStudentFromClass({
    required String studentId,
    required String className,
  }) {
    return TeacherService.removeStudentFromClass(studentId: studentId, className: className);
  }

  static Future<Map<String, dynamic>> getLessons(String className) {
    return TeacherService.getLessons(className);
  }

  static Future<Map<String, dynamic>> addLesson({
    required String title,
    required String subject,
    required String description,
    required String type,
    required String className,
    String? deadline,
    List<Map<String, dynamic>> files = const [],
  }) {
    return TeacherService.addLesson(
      title: title,
      subject: subject,
      description: description,
      type: type,
      className: className,
      deadline: deadline,
      files: files,
    );
  }

  static Future<Map<String, dynamic>> updateLesson({
    required String id,
    required String title,
    required String subject,
    required String description,
    required String type,
    String? deadline,
    List<Map<String, dynamic>> files = const [],
  }) {
    return TeacherService.updateLesson(
      id: id,
      title: title,
      subject: subject,
      description: description,
      type: type,
      deadline: deadline,
      files: files,
    );
  }

  static Future<Map<String, dynamic>> deleteLesson(String id) {
    return TeacherService.deleteLesson(id);
  }

  static Future<Map<String, dynamic>> getTeacherEvents({
    required String className,
    required String teacherId,
  }) {
    return TeacherService.getTeacherEvents(className: className, teacherId: teacherId);
  }

  static Future<Map<String, dynamic>> addEvent({
    required String title,
    required String description,
    required DateTime date,
    required String teacherId,
    required String teacherName,
    required String className,
    DateTime? responseDeadline,
  }) {
    return TeacherService.addEvent(
      title: title,
      description: description,
      date: date,
      teacherId: teacherId,
      teacherName: teacherName,
      className: className,
      responseDeadline: responseDeadline,
    );
  }

  static Future<Map<String, dynamic>> deleteEvent(String eventId) {
    return TeacherService.deleteEvent(eventId);
  }

  static Future<Map<String, dynamic>> getAgendaEvents({
    required String className,
    required String teacherId,
  }) {
    return TeacherService.getAgendaEvents(className: className, teacherId: teacherId);
  }

  static Future<Map<String, dynamic>> addAgendaEvent({
    required String className,
    required String subject,
    required String type,
    required String day,
    required String timeSlot,
    required DateTime date,
    required String teacherId,
    required String teacherName,
  }) {
    return TeacherService.addAgendaEvent(
      className: className,
      subject: subject,
      type: type,
      day: day,
      timeSlot: timeSlot,
      date: date,
      teacherId: teacherId,
      teacherName: teacherName,
    );
  }

  static Future<Map<String, dynamic>> deleteAgendaEvent(String eventId) {
    return TeacherService.deleteAgendaEvent(eventId);
  }

  static Future<Map<String, dynamic>> getAllExamsByClass(String className, String studentId) {
    return TeacherService.getAllExamsByClass(className, studentId);
  }

  static Future<Map<String, dynamic>> addExamGrade({
    required String examId,
    required String studentId,
    required String studentName,
    required String subject,
    required double grade,
    required String appreciation,
    String? photoUrl,
    required String teacherName,
  }) {
    return TeacherService.addExamGrade(
      examId: examId,
      studentId: studentId,
      studentName: studentName,
      subject: subject,
      grade: grade,
      appreciation: appreciation,
      photoUrl: photoUrl,
      teacherName: teacherName,
    );
  }

  static Future<Map<String, dynamic>> getExamGrades(String examId) {
    return TeacherService.getExamGrades(examId);
  }

  static Future<Map<String, dynamic>> getStudentExamGrades(String studentId) {
    return TeacherService.getStudentExamGrades(studentId);
  }

  static Future<Map<String, dynamic>> getStudentGrades(String studentId) {
    return TeacherService.getStudentGrades(studentId);
  }

  // ✅ getStudentAbsences est déjà dans TEACHER, ne pas dupliquer
  // static Future<Map<String, dynamic>> getStudentAbsences(String studentId) {
  //   return TeacherService.getStudentAbsences(studentId);
  // }

  static Future<Map<String, dynamic>> addAbsence({
    required String studentId,
    required DateTime date,
    required bool justified,
    required String reason,
    required String subject,
  }) {
    return TeacherService.addAbsence(
      studentId: studentId,
      date: date,
      justified: justified,
      reason: reason,
      subject: subject,
    );
  }

  static Future<Map<String, dynamic>> addGrade({
    required String studentId,
    required String subject,
    required double grade,
    required String appreciation,
  }) {
    return TeacherService.addGrade(
      studentId: studentId,
      subject: subject,
      grade: grade,
      appreciation: appreciation,
    );
  }

  static Future<Map<String, dynamic>> deleteGrade(String gradeId) {
    return TeacherService.deleteGrade(gradeId);
  }

  static Future<Map<String, dynamic>> saveSchedule({
    required String className,
    required Map<String, dynamic> schedule,
  }) {
    return TeacherService.saveSchedule(className: className, schedule: schedule);
  }

  static Future<Map<String, dynamic>> getSchedule(String className) {
    return TeacherService.getSchedule(className);
  }

  static Future<Map<String, dynamic>> getTeacherSchedule(String teacherEmail, String className) {
    return TeacherService.getTeacherSchedule(teacherEmail, className);
  }

  static Future<Map<String, dynamic>> getAllTeacherSchedules(String teacherEmail) {
    return TeacherService.getAllTeacherSchedules(teacherEmail);
  }

  static Future<Map<String, dynamic>> updateTeacherProfile({
    required String email,
    required String fullName,
    required String phoneNumber,
  }) {
    return TeacherService.updateTeacherProfile(
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }

  static Future<Map<String, dynamic>> changeTeacherPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) {
    return TeacherService.changeTeacherPassword(
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  // ==================== PARENT/STUDENT ====================
  static Future<Map<String, dynamic>> getStudentDetails(String studentId) {
    return ParentStudentService.getStudentDetails(studentId);
  }

  static Future<Map<String, dynamic>> getStudentGradesForParent(String studentId) {
    return ParentStudentService.getStudentGradesForParent(studentId);
  }

  static Future<Map<String, dynamic>> getStudentAbsencesForParent(String studentId) {
    return ParentStudentService.getStudentAbsencesForParent(studentId);
  }

  static Future<Map<String, dynamic>> getParentEvents(String studentId) {
    return ParentStudentService.getParentEvents(studentId);
  }

  static Future<Map<String, dynamic>> respondToEvent({
    required String eventId,
    required String studentId,
    required String studentName,
    required String response,
    String? comment,
  }) {
    return ParentStudentService.respondToEvent(
      eventId: eventId,
      studentId: studentId,
      studentName: studentName,
      response: response,
      comment: comment,
    );
  }

  // ==================== MÉTHODES PARENT ====================
  
  static Future<Map<String, dynamic>> getParentChildren(String parentEmail) {
    return ParentStudentService.getParentChildren(parentEmail);
  }

  static Future<Map<String, dynamic>> linkChildToParent({
    required String parentCode,
    required String parentId,
  }) {
    return ParentStudentService.linkChildToParent(
      parentCode: parentCode,
      parentId: parentId,
    );
  }

  static Future<Map<String, dynamic>> getChildLessons(String childId) {
    return ParentStudentService.getChildLessons(childId);
  }

  static Future<Map<String, dynamic>> getChildGrades(String childId) {
    return ParentStudentService.getChildGrades(childId);
  }

  static Future<Map<String, dynamic>> getChildExamGrades(String childId) {
    return ParentStudentService.getChildExamGrades(childId);
  }

  static Future<Map<String, dynamic>> getChildAbsences(String childId) {
    return ParentStudentService.getChildAbsences(childId);
  }

  static Future<Map<String, dynamic>> getChildEvents(String childId) {
    return ParentStudentService.getChildEvents(childId);
  }

  static Future<Map<String, dynamic>> parentRespondToEvent({
    required String eventId,
    required String studentId,
    required String studentName,
    required String response,
    String? comment,
  }) {
    return ParentStudentService.parentRespondToEvent(
      eventId: eventId,
      studentId: studentId,
      studentName: studentName,
      response: response,
      comment: comment,
    );
  }

  static Future<Map<String, dynamic>> getChildTeachers(String childId) {
    return ParentStudentService.getChildTeachers(childId);
  }

  static Future<Map<String, dynamic>> getParentConversations(String parentId) {
    return ParentStudentService.getParentConversations(parentId);
  }

  static Future<Map<String, dynamic>> sendParentMessage({
    required String receiverId,
    required String receiverName,
    required String receiverRole,
    required String message,
    List<Map<String, dynamic>> attachments = const [],
  }) {
    return ParentStudentService.sendParentMessage(
      receiverId: receiverId,
      receiverName: receiverName,
      receiverRole: receiverRole,
      message: message,
      attachments: attachments,
    );
  }

  // ==================== MESSAGES ====================
  static Future<Map<String, dynamic>> getConversations() {
    return MessageService.getConversations();
  }

  static Future<Map<String, dynamic>> getMessages(String contactId) {
    return MessageService.getMessages(contactId);
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String receiverName,
    required String receiverRole,
    required String message,
    List<Map<String, dynamic>> attachments = const [],
  }) {
    return MessageService.sendMessage(
      receiverId: receiverId,
      receiverName: receiverName,
      receiverRole: receiverRole,
      message: message,
      attachments: attachments,
    );
  }

  static Future<Map<String, dynamic>> markAsRead(String messageId) {
    return MessageService.markAsRead(messageId);
  }

  static Future<Map<String, dynamic>> getContacts() {
    return MessageService.getContacts();
  }

  // ==================== FILES ====================
  static Future<Map<String, dynamic>> uploadFile(File file) {
    return ApiClient.uploadFile(file);
  }

  static Future<Map<String, dynamic>> downloadFile(String filename, String originalName) {
    return ApiClient.downloadFile(filename, originalName);
  }

  static Future<void> logout() {
    return ApiClient.logout();
  }

  // ==================== ÉLÈVE ====================
  
  static Future<Map<String, dynamic>> getStudentInfo(String email) {
    return StudentService.getStudentInfo(email);
  }

  static Future<Map<String, dynamic>> getStudentLessons(String className) {
    return StudentService.getStudentLessons(className);
  }

  static Future<Map<String, dynamic>> getStudentSchedule(String className) {
    return StudentService.getStudentSchedule(className);
  }

  // ✅ Une seule déclaration de getStudentAbsences (celle-ci)
  static Future<Map<String, dynamic>> getStudentAbsences(String studentId) {
    return StudentService.getStudentAbsences(studentId);
  }

  static Future<Map<String, dynamic>> getStudentEvents(String studentId) {
    return StudentService.getStudentEvents(studentId);
  }

  static Future<Map<String, dynamic>> studentRespondToEvent({
    required String eventId,
    required String studentId,
    required String studentName,
    required String response,
    String? comment,
  }) {
    return StudentService.studentRespondToEvent(
      eventId: eventId,
      studentId: studentId,
      studentName: studentName,
      response: response,
      comment: comment,
    );
  }

  static Future<Map<String, dynamic>> getStudentConversations(String studentId) {
    return StudentService.getStudentConversations(studentId);
  }

  static Future<Map<String, dynamic>> sendStudentMessage({
    required String receiverId,
    required String receiverName,
    required String receiverRole,
    required String message,
    List<Map<String, dynamic>> attachments = const [],
  }) {
    return StudentService.sendStudentMessage(
      receiverId: receiverId,
      receiverName: receiverName,
      receiverRole: receiverRole,
      message: message,
      attachments: attachments,
    );
  }

  static Future<Map<String, dynamic>> updateStudentProfile({
    required String email,
    required String fullName,
    required String phoneNumber,
  }) {
    return StudentService.updateStudentProfile(
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }

  static Future<Map<String, dynamic>> changeStudentPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) {
    return StudentService.changeStudentPassword(
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}