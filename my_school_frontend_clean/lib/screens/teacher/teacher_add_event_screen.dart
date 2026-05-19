// lib/screens/teacher/teacher_add_event_screen.dart
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

class TeacherAddEventScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String className;

  const TeacherAddEventScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.className,
  });

  @override
  State<TeacherAddEventScreen> createState() => _TeacherAddEventScreenState();
}

class _TeacherAddEventScreenState extends State<TeacherAddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime _responseDeadline = DateTime.now();
  bool _isLoading = false;
  bool _hasDeadline = true;
  String? _deadlineError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isEventDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isEventDate ? _selectedDate : _responseDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0288D1),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isEventDate) {
          _selectedDate = picked;
          // Si la date de l'événement change, vérifier la validité de la date limite
          _validateDeadline();
        } else {
          _responseDeadline = picked;
          _validateDeadline();
        }
      });
    }
  }

  void _validateDeadline() {
    if (_hasDeadline && _responseDeadline.isAfter(_selectedDate)) {
      setState(() {
        _deadlineError = 'La date limite doit être antérieure à la date de l\'événement';
      });
    } else {
      setState(() {
        _deadlineError = null;
      });
    }
  }

  void _toggleDeadline(bool value) {
    setState(() {
      _hasDeadline = value;
      if (value) {
        _validateDeadline();
      } else {
        _deadlineError = null;
      }
    });
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Vérifier la validité de la date limite
    if (_hasDeadline && _responseDeadline.isAfter(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date limite doit être antérieure à la date de l\'événement'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.addEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        teacherId: widget.teacherId,
        teacherName: widget.teacherName,
        className: widget.className,
        responseDeadline: _hasDeadline ? _responseDeadline : null,
      );
      
      if (mounted && result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Événement créé'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Nouvel événement'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Titre *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Titre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Titre requis';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Description *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Description requise';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Date de l\'événement *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFF0288D1)),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Switch pour activer/désactiver la date limite
                    Row(
                      children: [
                        Switch(
                          value: _hasDeadline,
                          onChanged: _toggleDeadline,
                          activeColor: const Color(0xFF0288D1),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Fixer une date limite de réponse',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    
                    // Date limite (visible uniquement si activée)
                    if (_hasDeadline) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Date limite de réponse *',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFF0288D1)),
                              const SizedBox(width: 12),
                              Text(
                                '${_responseDeadline.day}/${_responseDeadline.month}/${_responseDeadline.year}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_deadlineError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _deadlineError!,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Les parents ne pourront plus répondre après cette date',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text('ANNULER'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveEvent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0288D1),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('CRÉER'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}