// lib/screens/parent/parent_courses_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/models/child_model.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// Écran de consultation des cours, devoirs et notifications pour le parent
/// Permet de visualiser le contenu pédagogique de l'enfant sélectionné
class ParentCoursesScreen extends StatefulWidget {
  final ChildModel? selectedChild;

  const ParentCoursesScreen({super.key, this.selectedChild});

  @override
  State<ParentCoursesScreen> createState() => _ParentCoursesScreenState();
}

class _ParentCoursesScreenState extends State<ParentCoursesScreen> {
  // ==================== VARIABLES D'ÉTAT ====================
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _homeworks = [];
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  final List<String> _tabs = ['Cours', 'Devoirs', 'Notification'];
  
  Map<String, bool> _downloadingFiles = {};

  // ==================== CYCLE DE VIE ====================
  
  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void didUpdateWidget(ParentCoursesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recharger les données si l'enfant sélectionné change
    if (oldWidget.selectedChild?.id != widget.selectedChild?.id) {
      _loadCourses();
    }
  }

  // ==================== CHARGEMENT DES DONNÉES ====================
  
  /// Charge les cours, devoirs et notifications depuis l'API
  Future<void> _loadCourses() async {
    // Cas où aucun enfant n'est sélectionné
    if (widget.selectedChild == null) {
      setState(() {
        _courses = [];
        _homeworks = [];
        _reminders = [];
        _isLoading = false;
      });
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getLessons(widget.selectedChild!.className);
      
      if (result['success'] && mounted) {
        final List<dynamic> lessons = result['lessons'] ?? [];
        
        setState(() {
          // Filtrer et mapper les cours
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
              
          // Filtrer et mapper les devoirs
          _homeworks = lessons
              .where((l) => l['type'] == 'Devoir')
              .map((l) => ({
                'id': l['_id'],
                'title': l['title'] ?? 'Sans titre',
                'subject': l['subject'] ?? 'Sans matière',
                'description': l['description'] ?? '',
                'deadline': l['deadline'] != null ? _formatDate(l['deadline']) : 'À définir',
                'files': l['files'] ?? [],
              }))
              .toList();
              
          // Filtrer et mapper les rappels
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
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Exception: $e');
      setState(() => _isLoading = false);
    }
  }

  // ==================== MÉTHODES DE FORMATAGE ====================
  
  /// Formate la date pour l'affichage
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

  /// Formate la taille d'un fichier (B, KB, MB)
  String _formatFileSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ==================== GESTION DES FICHIERS ====================
  
  /// Télécharge un fichier depuis le serveur
  Future<void> _downloadFile(String filename, String originalName) async {
    // Éviter les téléchargements multiples simultanés
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
      // Afficher un indicateur de chargement
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

  /// Affiche la boîte de dialogue de succès après téléchargement
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

  // ==================== AFFICHAGE DES DÉTAILS ====================
  
  /// Affiche les détails d'un cours ou d'un rappel
  void _showDetails(Map<String, dynamic> item) {
    final bool hasFiles = item['files'] != null && item['files'].isNotEmpty;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              item.containsKey('deadline') ? Icons.assignment : Icons.menu_book,
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
              if (item['deadline'] != null && item['deadline'].isNotEmpty)
                _buildDetailRow('Date limite', item['deadline']),
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

  /// Construit une ligne de détail (label + valeur)
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

  /// Construit un élément de fichier dans la liste
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
          // Icône du fichier
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
          
          // Informations du fichier
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
          
          // Bouton de téléchargement
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

  // ==================== BUILD UI ====================
  
  @override
  Widget build(BuildContext context) {
    final items = _selectedTab == 0 ? _courses : (_selectedTab == 1 ? _homeworks : _reminders);
    
    // Cas où aucun enfant n'est sélectionné
    if (widget.selectedChild == null) {
      return _buildNoChildSelected();
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Cours - ${widget.selectedChild!.fullName}'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barre d'onglets
                _buildTabBar(),
                
                // Liste des contenus
                Expanded(
                  child: items.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadCourses,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (context, index) => _buildContentCard(items[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  /// Construit l'écran quand aucun enfant n'est sélectionné
  Widget _buildNoChildSelected() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Cours et devoirs'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun enfant sélectionné',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la barre d'onglets
  Widget _buildTabBar() {
    return Container(
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
    );
  }

  /// Construit l'état vide (aucun contenu)
  Widget _buildEmptyState() {
    return Center(
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
            'Pour la classe: ${widget.selectedChild!.className}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Construit la carte d'un contenu (cours, devoir ou rappel)
  Widget _buildContentCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
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
                      ? '${item['subject']} • À rendre: ${item['deadline']}' 
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
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility, color: Color(0xFF0288D1)),
          onPressed: () => _showDetails(item),
        ),
      ),
    );
  }
}