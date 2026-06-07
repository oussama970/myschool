// lib/screens/teacher/teacher_homework_submissions_screen.dart
/// Écran enseignant pour consulter les soumissions de devoirs des élèves
/// Affiche le contenu des devoirs rendus et permet de télécharger les fichiers joints

import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class TeacherHomeworkSubmissionsScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;

  const TeacherHomeworkSubmissionsScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<TeacherHomeworkSubmissionsScreen> createState() => _TeacherHomeworkSubmissionsScreenState();
}

class _TeacherHomeworkSubmissionsScreenState extends State<TeacherHomeworkSubmissionsScreen> {
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = true;
  Map<String, bool> _downloadingFiles = {};

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  /// Charge la liste des soumissions pour ce devoir
  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getSubmissionsByLesson(widget.lessonId);
      if (result['success']) {
        setState(() {
          _submissions = List<Map<String, dynamic>>.from(result['submissions']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Télécharge et ouvre un fichier joint
  Future<void> _downloadFile(String filename, String originalName) async {
    if (_downloadingFiles[filename] == true) return;
    setState(() => _downloadingFiles[filename] = true);
    try {
      final result = await ApiService.downloadFile(filename, originalName);
      if (result['success'] && mounted) {
        await OpenFile.open(result['filePath']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingFiles[filename] = false);
    }
  }

  /// Formate la date de soumission
  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString.toString();
    }
  }

  /// Construit l'interface principale
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('📝 ${widget.lessonTitle} - Soumissions'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _submissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucune soumission', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSubmissions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _submissions.length,
                    itemBuilder: (context, index) {
                      final submission = _submissions[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête avec nom de l'élève
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF0288D1).withOpacity(0.1),
                                    child: Text(
                                      submission['studentName']?.substring(0, 1).toUpperCase() ?? '?',
                                      style: const TextStyle(color: Color(0xFF0288D1)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          submission['studentName'] ?? 'Élève',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Soumis le: ${_formatDate(submission['submittedAt'])}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Contenu texte de la soumission
                              if (submission['content'].isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(submission['content']),
                                ),
                              ],
                              
                              // Fichiers joints
                              if (submission['attachments'] != null && submission['attachments'].isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('📎 Fichiers joints:', style: TextStyle(fontWeight: FontWeight.w500)),
                                ...submission['attachments'].map((file) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.insert_drive_file, color: Color(0xFF0288D1)),
                                  title: Text(
                                    file['originalName'] ?? 'Fichier',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.download, size: 18),
                                    onPressed: () => _downloadFile(file['filename'], file['originalName']),
                                  ),
                                )),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}