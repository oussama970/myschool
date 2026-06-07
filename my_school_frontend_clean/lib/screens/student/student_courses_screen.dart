// lib/screens/student/student_courses_screen.dart
/// Écran étudiant permettant de consulter les cours, devoirs et rappels
/// Fonctionnalités: téléchargement de fichiers, soumission de devoirs avec pièces jointes,
/// visualisation des notes et retours des enseignants

import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class StudentCoursesScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentClass;

  const StudentCoursesScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentClass,
  });

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _homeworks = [];
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  final List<String> _tabs = ['Cours', 'Devoirs', 'Notification'];
  Map<String, bool> _downloadingFiles = {};
  
  // Pour le suivi des soumissions
  Map<String, Map<String, dynamic>> _submissions = {};

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  /// Charge tous les cours, devoirs et rappels depuis l'API
  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getStudentLessons(widget.studentClass);
      
      if (result['success'] && mounted) {
        final List<dynamic> lessons = result['lessons'] ?? [];
        
        setState(() {
          _courses = lessons
              .where((l) => l['type'] == 'Cours')
              .map((l) => ({
                'id': l['_id'],
                'title': l['title'] ?? 'Sans titre',
                'subject': l['subject'] ?? 'Sans matière',
                'description': l['description'] ?? '',
                'date': _formatDate(l['createdAt']),
                'files': l['files'] ?? [],
              }))
              .toList();
              
          _homeworks = lessons
              .where((l) => l['type'] == 'Devoir')
              .map((l) => ({
                'id': l['_id'],
                'title': l['title'] ?? 'Sans titre',
                'subject': l['subject'] ?? 'Sans matière',
                'description': l['description'] ?? '',
                'files': l['files'] ?? [],
              }))
              .toList();
              
          _reminders = lessons
              .where((l) => l['type'] == 'Rappel')
              .map((l) => ({
                'id': l['_id'],
                'title': l['title'] ?? 'Sans titre',
                'description': l['description'] ?? '',
                'date': _formatDate(l['createdAt']),
              }))
              .toList();
        });
        
        await _loadSubmissions();
        _isLoading = false;
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Exception: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Charge les soumissions de l'étudiant pour chaque devoir
  Future<void> _loadSubmissions() async {
    for (var homework in _homeworks) {
      final result = await ApiService.getStudentSubmissionForLesson(homework['id']);
      if (result['success'] && result['submission'] != null) {
        _submissions[homework['id']] = result['submission'];
      }
    }
    setState(() {});
  }

  /// Formate une date au format JJ/MM/AAAA
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Retourne l'emoji correspondant au type de fichier
  String _getFileIcon(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    switch(ext) {
      case 'pdf': return '📄';
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'webp': return '🖼️';
      case 'doc': case 'docx': return '📝';
      case 'xls': case 'xlsx': return '📊';
      case 'ppt': case 'pptx': return '📽️';
      case 'mp4': case 'mov': case 'avi': return '🎬';
      case 'mp3': case 'wav': return '🎵';
      default: return '📎';
    }
  }

  /// Télécharge un fichier depuis le serveur
  Future<void> _downloadFile(String filename, String originalName) async {
    if (_downloadingFiles[filename] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement en cours...'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _downloadingFiles[filename] = true;
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Téléchargement de $originalName...'),
            ],
          ),
        ),
      );

      final result = await ApiService.downloadFile(filename, originalName);

      if (mounted) Navigator.pop(context);

      if (result['success'] && mounted) {
        final filePath = result['filePath'];
        _showDownloadSuccessDialog(filePath, originalName);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${result['message'] ?? 'Téléchargement échoué'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingFiles[filename] = false;
        });
      }
    }
  }

  /// Affiche un dialogue de succès après téléchargement
  void _showDownloadSuccessDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Téléchargement terminé',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fichier sauvegardé: $fileName',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Emplacement: Dossier Documents',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FERMER'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final result = await OpenFile.open(filePath);
              if (result.type != ResultType.done) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Impossible d\'ouvrir le fichier: ${result.message}'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            icon: const Icon(Icons.open_in_browser, size: 18),
            label: const Text('OUVRIR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0288D1),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche les détails d'un cours ou d'un rappel
  void _showDetails(Map<String, dynamic> item) {
    final bool hasFiles = item['files'] != null && item['files'].isNotEmpty;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.menu_book,
              color: const Color(0xFF0288D1),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['title'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item['subject'] != null && item['subject'].isNotEmpty)
                _buildDetailRow('Matière', item['subject']),
              if (item['date'] != null && item['date'].isNotEmpty)
                _buildDetailRow('Date', item['date']),
              if (item['description'].isNotEmpty) ...[
                const Divider(height: 24),
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(item['description']),
              ],
              if (hasFiles) ...[
                const Divider(height: 24),
                const Text('📎 Fichiers joints:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...item['files'].map<Widget>((file) => _buildFileTile(file)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FERMER'),
          ),
        ],
      ),
    );
  }

  /// Affiche le dialogue de soumission d'un devoir
  void _showSubmitHomeworkDialog(Map<String, dynamic> homework) {
    final TextEditingController _contentController = TextEditingController();
    List<Map<String, dynamic>> _attachedFiles = [];
    bool _isSubmitting = false;
    final ImagePicker _picker = ImagePicker();

    final existingSubmission = _submissions[homework['id']];
    if (existingSubmission != null) {
      _contentController.text = existingSubmission['content'] ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                      left: 20,
                      right: 20,
                      top: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          existingSubmission != null ? '✏️ Modifier mon devoir' : '📝 Rendre mon devoir',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF01579B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          homework['title'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        const Text(
                          'Votre réponse (texte)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contentController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Écrivez votre réponse ici...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '📎 Fichiers joints',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.camera_alt, color: Color(0xFF0288D1)),
                                  onPressed: () async {
                                    final XFile? photo = await _picker.pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 80,
                                    );
                                    if (photo != null) {
                                      setModalState(() {
                                        _attachedFiles.add({
                                          'name': photo.name,
                                          'path': photo.path,
                                          'file': File(photo.path),
                                          'type': 'image',
                                        });
                                      });
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.photo_library, color: Color(0xFF0288D1)),
                                  onPressed: () async {
                                    final XFile? image = await _picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 80,
                                    );
                                    if (image != null) {
                                      setModalState(() {
                                        _attachedFiles.add({
                                          'name': image.name,
                                          'path': image.path,
                                          'file': File(image.path),
                                          'type': 'image',
                                        });
                                      });
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.attach_file, color: Color(0xFF0288D1)),
                                  onPressed: () async {
                                    FilePickerResult? result = await FilePicker.platform.pickFiles();
                                    if (result != null && result.files.single.path != null) {
                                      setModalState(() {
                                        _attachedFiles.add({
                                          'name': result.files.single.name,
                                          'path': result.files.single.path,
                                          'file': File(result.files.single.path!),
                                          'type': 'file',
                                        });
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        if (_attachedFiles.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: _attachedFiles.asMap().entries.map((entry) {
                                int index = entry.key;
                                var file = entry.value;
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    file['type'] == 'image' ? Icons.image : Icons.insert_drive_file,
                                    color: const Color(0xFF0288D1),
                                  ),
                                  title: Text(
                                    file['name'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                    onPressed: () {
                                      setModalState(() {
                                        _attachedFiles.removeAt(index);
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('ANNULER'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () async {
                                        if (_contentController.text.trim().isEmpty && _attachedFiles.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Veuillez écrire une réponse ou joindre un fichier'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                          return;
                                        }
                                        
                                        setModalState(() => _isSubmitting = true);
                                        
                                        List<Map<String, dynamic>> uploadedFiles = [];
                                        for (var file in _attachedFiles) {
                                          if (file.containsKey('file')) {
                                            final uploadResult = await ApiService.uploadFile(file['file']);
                                            if (uploadResult['success']) {
                                              uploadedFiles.add({
                                                'filename': uploadResult['file']['filename'],
                                                'originalName': uploadResult['file']['originalName'],
                                                'fileType': uploadResult['file']['fileType'],
                                                'fileSize': uploadResult['file']['fileSize'],
                                              });
                                            }
                                          }
                                        }
                                        
                                        final result = await ApiService.submitHomework(
                                          lessonId: homework['id'],
                                          content: _contentController.text.trim(),
                                          attachments: uploadedFiles,
                                        );
                                        
                                        if (mounted) {
                                          if (result['success']) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('✅ Devoir soumis avec succès !'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            Navigator.pop(context);
                                            _loadCourses();
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('❌ Erreur: ${result['message']}'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                        setModalState(() => _isSubmitting = false);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0288D1),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('SOUMETTRE'),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Affiche les détails d'un devoir avec la soumission et la note
  void _showHomeworkDetails(Map<String, dynamic> item) {
    final submission = _submissions[item['id']];
    final hasFiles = item['files'] != null && item['files'].isNotEmpty;
    final hasSubmission = submission != null;
    final isGraded = hasSubmission && submission['grade'] != null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0288D1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.assignment, color: Color(0xFF0288D1), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Matière', item['subject']),
                  if (item['description'].isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(item['description']),
                  ],
                  if (hasFiles) ...[
                    const Divider(height: 24),
                    const Text('📎 Fichiers du devoir:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...item['files'].map<Widget>((file) => _buildFileTile(file)),
                  ],
                  
                  const Divider(height: 24),
                  
                  const Text('📤 MA SOUMISSION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  
                  if (hasSubmission) ...[
                    if (isGraded)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Devoir noté: ${submission['grade']}/20',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Soumis le: ${_formatDateTime(submission['submittedAt'])}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    if (submission['content'] != null && submission['content'].isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ma réponse:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(submission['content']),
                          ],
                        ),
                      ),
                    
                    if (submission['attachments'] != null && submission['attachments'].isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Mes fichiers joints:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      ...submission['attachments'].map<Widget>((file) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.insert_drive_file, color: Color(0xFF0288D1)),
                          title: Text(
                            file['originalName'] ?? file['filename'] ?? 'Fichier',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.download, size: 18, color: Color(0xFF0288D1)),
                            onPressed: () => _downloadFile(file['filename'], file['originalName']),
                          ),
                        ),
                      )),
                    ],
                    
                    if (submission['feedback'] != null && submission['feedback'].isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✏️ Commentaire de l\'enseignant:', 
                                style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(submission['feedback']),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_upload, size: 48, color: Colors.orange),
                          const SizedBox(height: 8),
                          const Text(
                            'Vous n\'avez pas encore rendu ce devoir',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showSubmitHomeworkDialog(item);
                            },
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Rendre mon devoir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0288D1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Formate une date et heure pour l'affichage
  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      final date = DateTime.parse(dateTime.toString());
      return '${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  /// Construit un widget de fichier avec icône, nom, taille et bouton de téléchargement
  Widget _buildFileTile(Map<String, dynamic> file) {
    final String filename = file['filename'] ?? '';
    final String originalName = file['originalName'] ?? 'Fichier';
    final bool isDownloading = _downloadingFiles[filename] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0288D1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _getFileIcon(originalName),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  originalName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatFileSize(file['fileSize'] ?? 0),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (isDownloading)
            const SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _downloadFile(filename, originalName),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.download,
                    color: Color(0xFF0288D1),
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Formate la taille d'un fichier (B, KB, MB)
  String _formatFileSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Construit une ligne de détail avec label et valeur
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Construit l'interface principale avec les onglets
  @override
  Widget build(BuildContext context) {
    final items = _selectedTab == 0 ? _courses : (_selectedTab == 1 ? _homeworks : _reminders);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Cours - ${widget.studentName}'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barre d'onglets
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == index ? const Color(0xFF0288D1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              _tabs[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedTab == index ? Colors.white : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                
                // Liste des éléments
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun ${_tabs[_selectedTab].toLowerCase()}',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pour ${widget.studentName}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCourses,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final isHomework = _selectedTab == 1;
                              final hasSubmission = _submissions[item['id']] != null;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: Stack(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0288D1).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _selectedTab == 0 ? Icons.menu_book : (_selectedTab == 1 ? Icons.assignment : Icons.notifications),
                                          color: const Color(0xFF0288D1),
                                          size: 28,
                                        ),
                                      ),
                                      if (isHomework && hasSubmission)
                                        Positioned(
                                          right: -4,
                                          top: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    item['title'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedTab == 0 
                                            ? '${item['subject']} • ${item['date']}' 
                                            : (_selectedTab == 1 
                                                ? item['subject']
                                                : item['date']),
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item['files'] != null && item['files'].isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.attach_file, size: 12, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${item['files'].length} fichier(s) joint(s)',
                                                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (isHomework && hasSubmission)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            '📤 Soumis',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.visibility, color: Color(0xFF0288D1)),
                                    onPressed: () {
                                      if (isHomework) {
                                        _showHomeworkDetails(item);
                                      } else {
                                        _showDetails(item);
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}