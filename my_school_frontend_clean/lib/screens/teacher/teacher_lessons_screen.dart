import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_school_frontend/services/api_service.dart';

class TeacherLessonsScreen extends StatefulWidget {
  final String teacherEmail;
  final String className;

  const TeacherLessonsScreen({
    super.key,
    required this.teacherEmail,
    required this.className,
  });

  @override
  State<TeacherLessonsScreen> createState() => _TeacherLessonsScreenState();
}

class _TeacherLessonsScreenState extends State<TeacherLessonsScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['📚 Cours', '📝 Devoirs', '🔔 Rappels'];
  
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _homeworks = [];
  List<Map<String, dynamic>> _reminders = [];
  
  bool _isLoading = true;
  bool _isEditing = false;
  String? _editingId;
  String _editingType = '';
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _deadlineController = TextEditingController();
  String _selectedSubject = 'Maths';
  String _selectedType = 'Cours';
  List<Map<String, dynamic>> _attachedFiles = [];
  bool _showDeadline = false;

  final List<String> _subjects = [
    'Maths', 'Français', 'Arabe', 'Anglais', 'Histoire', 
    'Sciences', 'EPS', 'Arts', 'Musique', 'Technologie'
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _dateController.text = _getCurrentDate();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getLessons(widget.className);
      
      if (result['success']) {
        final List<dynamic> lessons = result['lessons'] ?? [];
        
        setState(() {
          _courses = lessons
              .where((l) => l['type'] == 'Cours')
              .map((l) => ({
                    'id': l['_id'],
                    'title': l['title'] ?? 'Sans titre',
                    'subject': l['subject'] ?? 'Sans matière',
                    'date': _formatDate(l['createdAt']),
                    'hasFiles': (l['files'] as List?)?.isNotEmpty ?? false,
                    'description': l['description'] ?? '',
                  }))
              .toList();
              
          _homeworks = lessons
              .where((l) => l['type'] == 'Devoir')
              .map((l) => ({
                    'id': l['_id'],
                    'title': l['title'] ?? 'Sans titre',
                    'subject': l['subject'] ?? 'Sans matière',
                    'deadline': l['deadline'] != null && l['deadline'].toString().isNotEmpty 
                        ? _formatDate(l['deadline']) 
                        : 'À définir',
                    'hasFiles': (l['files'] as List?)?.isNotEmpty ?? false,
                    'description': l['description'] ?? '',
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
          
          _isLoading = false;
        });
      } else {
        _loadMockData();
      }
    } catch (e) {
      print('Erreur chargement: $e');
      _loadMockData();
    }
  }

  void _loadMockData() {
    setState(() {
      _courses = [
        {'id': '1', 'title': 'Les fractions', 'subject': 'Maths', 'date': '14/03/2024', 'hasFiles': true, 'description': 'Introduction aux fractions'},
        {'id': '2', 'title': 'Le passé simple', 'subject': 'Français', 'date': '13/03/2024', 'hasFiles': true, 'description': 'Conjugaison du passé simple'},
      ];
      _homeworks = [
        {'id': '4', 'title': 'Exercice Maths', 'subject': 'Maths', 'deadline': '20/03/2024', 'hasFiles': true, 'description': 'Exercices page 42'},
      ];
      _reminders = [
        {'id': '6', 'title': 'Réunion parents', 'description': '18h salle 101', 'date': '20/03/2024'},
        {'id': '7', 'title': 'Sortie scolaire', 'description': 'Prévoir pique-nique', 'date': '05/04/2024'},
      ];
      _isLoading = false;
    });
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _deadlineController.clear();
    _attachedFiles.clear();
    _selectedSubject = 'Maths';
    _selectedType = 'Cours';
    _showDeadline = false;
    _isEditing = false;
    _editingId = null;
    _editingType = '';
    _dateController.text = _getCurrentDate();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (photo != null) {
        setState(() {
          _attachedFiles.add({
            'name': photo.name,
            'path': photo.path,
            'type': 'image',
          });
        });
        _showSnackBar('📸 Photo ajoutée: ${photo.name}', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Erreur: $e', Colors.red);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _attachedFiles.add({
            'name': image.name,
            'path': image.path,
            'type': 'image',
          });
        });
        _showSnackBar('🖼️ Image ajoutée: ${image.name}', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Erreur: $e', Colors.red);
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'mp4', 'ppt', 'xls'],
      );
      
      if (result != null) {
        for (var file in result.files) {
          setState(() {
            _attachedFiles.add({
              'name': file.name,
              'path': file.path,
              'size': file.size,
              'type': 'file',
            });
          });
        }
        _showSnackBar('📎 ${result.files.length} fichier(s) ajouté(s)', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Erreur: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 1)),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ajouter une pièce jointe',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0288D1), size: 28),
                title: const Text('Prendre une photo'),
                subtitle: const Text('Utiliser l\'appareil photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF4CAF9F), size: 28),
                title: const Text('Choisir depuis la galerie'),
                subtitle: const Text('Sélectionner une image existante'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Color(0xFFFF9800), size: 28),
                title: const Text('Ajouter un fichier'),
                subtitle: const Text('PDF, DOC, TXT, etc.'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  void _editContent(Map<String, dynamic> item, String type) {
    _resetForm();
    _isEditing = true;
    _editingId = item['id'].toString();
    _editingType = type;
    _selectedType = type;
    
    _titleController.text = item['title'] ?? '';
    _descriptionController.text = item['description'] ?? '';
    
    if (type == 'Rappel') {
      _selectedSubject = 'Maths';
      _showDeadline = false;
    } else if (type == 'Cours') {
      _selectedSubject = item['subject'] ?? 'Maths';
      _showDeadline = false;
    } else if (type == 'Devoir') {
      _selectedSubject = item['subject'] ?? 'Maths';
      _showDeadline = true;
      _deadlineController.text = item['deadline'] ?? '';
    }
    
    _showFormDialog(isEditing: true);
  }

  Future<void> _saveContent() async {
    if (_titleController.text.isEmpty) {
      _showSnackBar('Veuillez entrer un titre', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      List<String> fileNames = _attachedFiles.map((f) => f['name'] as String).toList();
      Map<String, dynamic> result;
      
      final subject = _selectedType == 'Rappel' ? '' : _selectedSubject;
      
      String? deadlineValue = null;
      if (_selectedType == 'Devoir') {
        if (_deadlineController.text.isEmpty) {
          _showSnackBar('Veuillez entrer une date limite pour le devoir', Colors.orange);
          setState(() => _isLoading = false);
          return;
        }
        deadlineValue = _deadlineController.text;
      }
      
      print('📤 Envoi: Type=$_selectedType, Titre=${_titleController.text}, Date=$deadlineValue');
      
      if (_isEditing && _editingId != null && _editingId!.isNotEmpty) {
        result = await ApiService.updateLesson(
          id: _editingId!,
          title: _titleController.text,
          subject: subject,
          description: _descriptionController.text,
          type: _selectedType,
          deadline: deadlineValue,
          files: fileNames,
        );
      } else {
        result = await ApiService.addLesson(
          title: _titleController.text,
          subject: subject,
          description: _descriptionController.text,
          type: _selectedType,
          className: widget.className,
          deadline: deadlineValue,
          files: fileNames,
        );
      }
      
      print('📡 Réponse: $result');
      
      if (result['success']) {
        await _loadData();
        _resetForm();
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar(_isEditing ? '✅ Contenu modifié' : '✅ Contenu ajouté', Colors.green);
        }
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(result['message'] ?? 'Erreur', Colors.red);
      }
    } catch (e) {
      print('❌ Erreur: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: $e', Colors.red);
    }
  }

  void _deleteContent(int index, String type) {
    String? id;
    if (type == 'Cours' && index < _courses.length) {
      id = _courses[index]['id'];
    } else if (type == 'Devoir' && index < _homeworks.length) {
      id = _homeworks[index]['id'];
    } else if (type == 'Rappels' && index < _reminders.length) {
      id = _reminders[index]['id'];
    }
    
    if (id == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce contenu ?\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              final result = await ApiService.deleteLesson(id!);
              
              if (result['success']) {
                await _loadData();
                _showSnackBar('🗑️ Contenu supprimé', Colors.red);
              } else {
                setState(() => _isLoading = false);
                _showSnackBar(result['message'] ?? 'Erreur', Colors.red);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
  }

  void _showFormDialog({bool isEditing = false}) {
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
              initialChildSize: 0.95,
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
                          isEditing ? '✏️ MODIFIER LE CONTENU' : '➕ AJOUTER UN CONTENU',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
                        ),
                        const SizedBox(height: 20),
                        
                        // Type
                        const Text('Type *', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedType,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'Cours', child: Text('📚 Cours')),
                              DropdownMenuItem(value: 'Devoir', child: Text('📝 Devoir')),
                              DropdownMenuItem(value: 'Rappel', child: Text('🔔 Rappel')),
                            ],
                            onChanged: (value) {
                              setModalState(() {
                                _selectedType = value!;
                                _showDeadline = value == 'Devoir';
                              });
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Titre
                        const Text('Titre *', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'Entrez le titre',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Matière
                        if (_selectedType != 'Rappel') ...[
                          const Text('Matière *', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedSubject,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: _subjects.map((subject) {
                                return DropdownMenuItem(value: subject, child: Text(subject));
                              }).toList(),
                              onChanged: (value) {
                                setModalState(() => _selectedSubject = value!);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Description
                        const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Description...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Date
                        const Text('Date *', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            hintText: 'JJ/MM/AAAA',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        
                        // Date limite (uniquement pour les devoirs)
                        if (_showDeadline) ...[
                          const SizedBox(height: 16),
                          const Text('Date limite *', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _deadlineController,
                            decoration: InputDecoration(
                              hintText: 'JJ/MM/AAAA',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Pièces jointes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pièces jointes',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showAttachmentOptions,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Ajouter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0288D1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Liste des fichiers attachés
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: _attachedFiles.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Icon(Icons.attach_file, size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text(
                                          'Aucun fichier joint',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        Text(
                                          'Appuyez sur + pour ajouter',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (int i = 0; i < _attachedFiles.length; i++)
                                      _buildAttachmentItem(_attachedFiles[i], i, setModalState),
                                  ],
                                ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _resetForm();
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey,
                                  side: const BorderSide(color: Colors.grey),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                                child: const Text('ANNULER'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveContent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0288D1),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                                child: Text(isEditing ? 'MODIFIER' : 'PUBLIER'),
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

  Widget _buildAttachmentItem(Map<String, dynamic> file, int index, StateSetter setModalState) {
    IconData icon;
    Color color;
    
    String name = file['name'] ?? 'fichier';
    
    if (name.toLowerCase().endsWith('.pdf')) {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (name.toLowerCase().endsWith('.doc') || name.toLowerCase().endsWith('.docx')) {
      icon = Icons.description;
      color = Colors.blue;
    } else if (name.toLowerCase().endsWith('.xls') || name.toLowerCase().endsWith('.xlsx')) {
      icon = Icons.table_chart;
      color = Colors.green;
    } else if (name.toLowerCase().endsWith('.ppt') || name.toLowerCase().endsWith('.pptx')) {
      icon = Icons.slideshow;
      color = Colors.orange;
    } else if (name.toLowerCase().endsWith('.jpg') || name.toLowerCase().endsWith('.png') || name.toLowerCase().endsWith('.jpeg')) {
      icon = Icons.image;
      color = Colors.purple;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.length > 30 ? '${name.substring(0, 27)}...' : name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (file['size'] != null)
                  Text(
                    _formatFileSize(file['size']),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.red),
            onPressed: () {
              setModalState(() {
                _attachedFiles.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showAddDialog() {
    _resetForm();
    _showFormDialog(isEditing: false);
  }

  void _showDetails(Map<String, dynamic> item, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['title'] ?? 'Détails'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${type == 'Rappels' ? 'Rappel' : type}'),
            if (type != 'Rappels') ...[
              const SizedBox(height: 8),
              Text('Matière: ${item['subject'] ?? '-'}'),
            ],
            const SizedBox(height: 8),
            Text('Date: ${item['date'] ?? item['deadline'] ?? '-'}'),
            if (item['description'] != null && item['description'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Description: ${item['description']}'),
            ],
            if (item['hasFiles'] == true) ...[
              const SizedBox(height: 8),
              const Text('📎 Fichier(s) joint(s)', style: TextStyle(color: Colors.blue)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('FERMER')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Contenus pédagogiques'),
        backgroundColor: const Color(0xFF01579B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
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
          ),

          const SizedBox(height: 20),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 0
                    ? _buildList(_courses, 'Cours')
                    : _selectedTab == 1
                        ? _buildList(_homeworks, 'Devoir')
                        : _buildList(_reminders, 'Rappels'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF0288D1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun ${type.toLowerCase()}s', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final displayType = type == 'Devoir' ? 'Devoir' : (type == 'Rappels' ? 'Rappel' : type);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (type == 'Devoir' ? const Color(0xFF4CAF9F) : const Color(0xFF0288D1)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  type == 'Cours' ? Icons.menu_book : type == 'Devoir' ? Icons.assignment : Icons.notifications,
                  color: type == 'Devoir' ? const Color(0xFF4CAF9F) : const Color(0xFF0288D1),
                ),
              ),
              title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (type != 'Rappels')
                    Text('${item['subject'] ?? ''} • ${item['date'] ?? item['deadline'] ?? ''}')
                  else
                    Text(item['date'] ?? ''),
                  if (item['hasFiles'] == true)
                    const Text('📎 Fichier joint', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20, color: Color(0xFF0288D1)),
                    onPressed: () => _showDetails(item, type),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                    onPressed: () => _editContent(item, displayType),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _deleteContent(index, type),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}