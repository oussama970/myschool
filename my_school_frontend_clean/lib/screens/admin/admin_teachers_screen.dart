import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'admin_add_teacher_screen.dart';

/// Écran de gestion des enseignants pour l'administrateur
/// Permet de visualiser la liste des enseignants,
/// de rechercher un enseignant, d'en ajouter ou d'en supprimer
class AdminTeachersScreen extends StatefulWidget {
  final String adminEmail;

  const AdminTeachersScreen({super.key, required this.adminEmail});

  @override
  State<AdminTeachersScreen> createState() => _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends State<AdminTeachersScreen> {
  // ==================== CONTRÔLEURS & ÉTATS ====================
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _teachers = [];

  // ==================== CYCLE DE VIE ====================
  
  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================== CHARGEMENT DES DONNÉES ====================
  
  /// Charge la liste des enseignants depuis l'API
  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getTeachers();
      
      if (result['success']) {
        setState(() {
          _teachers = result['teachers'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur chargement enseignants: $e');
      setState(() => _isLoading = false);
    }
  }

  // ==================== GESTION DES ENSEIGNANTS ====================
  
  /// Supprime un enseignant après confirmation
  Future<void> _deleteTeacher(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer cet enseignant ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiService.deleteTeacher(id);
              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enseignant supprimé'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadTeachers();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ==================== MÉTHODES DE FILTRAGE ====================
  
  /// Filtre les enseignants selon le terme de recherche
  List<dynamic> _getFilteredTeachers() {
    if (_searchController.text.isEmpty) return _teachers;
    return _teachers.where((t) =>
      t['fullName'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
      t['email'].toString().toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
  }

  // ==================== BUILD UI ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // En-tête avec titre et bouton d'ajout
          _buildHeader(),
          
          // Barre de recherche
          _buildSearchBar(),

          const SizedBox(height: 20),

          // Liste des enseignants
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredTeachers().isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _getFilteredTeachers().length,
                        itemBuilder: (context, index) => _buildTeacherCard(_getFilteredTeachers()[index]),
                      ),
          ),
        ],
      ),
    );
  }

  /// Construit l'en-tête avec le titre et le bouton d'ajout
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '👥 ENSEIGNANTS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF01579B),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminAddTeacherScreen(
                    adminEmail: widget.adminEmail,
                  ),
                ),
              );
              if (result == true) _loadTeachers();
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0288D1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la barre de recherche
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            hintText: '🔍 Rechercher un enseignant...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF0288D1)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  /// Affiche l'état vide (aucun enseignant trouvé)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun enseignant trouvé',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la carte d'un enseignant
  Widget _buildTeacherCard(dynamic teacher) {
    final subjects = teacher['subjects'] as List? ?? [];
    final assignedClasses = teacher['assignedClasses'] as List? ?? [];
    
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
            // En-tête : nom et bouton suppression
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    teacher['fullName'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF01579B),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () => _deleteTeacher(teacher['_id']),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Email
            Text(
              teacher['email'] ?? '',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            // Matières et classes assignées
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // Badge Matière
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '📚 ${subjects.isNotEmpty ? subjects.join(', ') : '-'}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                // Badge Classes
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF9F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🏫 ${assignedClasses.isNotEmpty ? assignedClasses.join(', ') : '-'}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}