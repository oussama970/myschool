import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class TeacherAddContentScreen extends StatefulWidget {
  final String teacherEmail;
  final String className;

  const TeacherAddContentScreen({
    super.key,
    required this.teacherEmail,
    required this.className,
  });

  @override
  State<TeacherAddContentScreen> createState() => _TeacherAddContentScreenState();
}

class _TeacherAddContentScreenState extends State<TeacherAddContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _deadlineController = TextEditingController();

  String _selectedType = 'Cours';
  String _selectedSubject = 'Maths';
  bool _showDeadline = false;
  List<Map<String, String>> _attachedFiles = [];

  final List<String> _types = ['Cours', 'Devoir', 'Rappel'];
  final List<String> _subjects = [
    'Maths', 'Français', 'Histoire', 'Sciences', 'Anglais', 'EPS', 'Arts', 'Musique'
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text = _getCurrentDate();
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    
    if (result != null) {
      setState(() {
        _attachedFiles.add({
          'name': result.files.single.name,
          'size': '${(result.files.single.size / 1024 / 1024).toStringAsFixed(1)} Mo',
        });
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '➕ Ajouter un contenu',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    items: _types.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
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
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Entrez le titre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le titre est requis';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Matière
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
                      setState(() {
                        _selectedSubject = value!;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Description du contenu...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 16),

                // Date
                const Text('Date *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    hintText: 'JJ/MM/AAAA',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La date est requise';
                    }
                    return null;
                  },
                ),

                if (_showDeadline) ...[
                  const SizedBox(height: 16),
                  const Text('Date limite', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _deadlineController,
                    decoration: InputDecoration(
                      hintText: 'JJ/MM/AAAA',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Pièces jointes
                const Text(
                  'Pièces jointes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      // Liste des fichiers
                      if (_attachedFiles.isNotEmpty)
                        ..._attachedFiles.asMap().entries.map((entry) {
                          int index = entry.key;
                          var file = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file, size: 20, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${file['name']} (${file['size']})',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () => _removeFile(index),
                                ),
                              ],
                            ),
                          );
                        }),
                      
                      // Bouton ajouter
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Ajouter un fichier'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0288D1),
                          side: const BorderSide(color: Color(0xFF0288D1)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      Text(
                        'Types acceptés: Images (jpg, png) - max 5 Mo, Documents (pdf, doc) - max 10 Mo',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pop(context, true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Contenu publié avec succès'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('PUBLIER'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}