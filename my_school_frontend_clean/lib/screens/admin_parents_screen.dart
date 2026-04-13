import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

class AdminParentsScreen extends StatefulWidget {
  final String adminEmail;

  const AdminParentsScreen({super.key, required this.adminEmail});

  @override
  State<AdminParentsScreen> createState() => _AdminParentsScreenState();
}

class _AdminParentsScreenState extends State<AdminParentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _parents = [];

  @override
  void initState() {
    super.initState();
    _loadParents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParents() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getParents();
      
      print('========== CHARGEMENT PARENTS ==========');
      print('Succès: ${result['success']}');
      
      if (result['success']) {
        final parents = result['parents'] ?? [];
        print('${parents.length} parents chargés');
        
        // Afficher le premier parent pour debug
        if (parents.isNotEmpty) {
          print('Premier parent: ${parents[0]['fullName']}');
          print('Enfants: ${parents[0]['children']}');
        }
        
        setState(() {
          _parents = parents;
          _isLoading = false;
        });
      } else {
        print('Erreur: ${result['message']}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteParent(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer ce parent ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiService.deleteParent(id);
              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Parent supprimé'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadParents();
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

  List<dynamic> _getFilteredParents() {
    if (_searchController.text.isEmpty) return _parents;
    return _parents.where((p) =>
      p['fullName'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
      p['email'].toString().toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '👨‍👩‍👧 PARENTS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF01579B),
              ),
            ),
          ),

          Padding(
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
                  hintText: '🔍 Rechercher un parent...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0288D1)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredParents().isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.family_restroom_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun parent trouvé',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _getFilteredParents().length,
                        itemBuilder: (context, index) {
                          final parent = _getFilteredParents()[index];
                          final children = parent['children'] as List? ?? [];
                          
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
                                  // En-tête avec nom et bouton suppression
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              parent['fullName'] ?? 'Nom inconnu',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF01579B),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.email, size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    parent['email'] ?? 'Email non disponible',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deleteParent(parent['_id']),
                                      ),
                                    ],
                                  ),
                                  
                                  // Téléphone
                                  if (parent['phoneNumber'] != null && parent['phoneNumber'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            parent['phoneNumber'],
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  
                                  // Enfants liés
                                  const Text(
                                    '👶 Enfants liés:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF01579B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Liste des enfants
                                  children.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Text(
                                            'Aucun enfant lié',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        )
                                      : Column(
                                          children: children.map((child) => Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.child_care, size: 16, color: Color(0xFF4CAF9F)),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        child['fullName'] ?? 'Nom inconnu',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF01579B),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 24),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.email, size: 12, color: Colors.grey),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          child['email'] ?? 'Email non disponible',
                                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (child['className'] != null && child['className'].toString().isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 24, top: 2),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.class_, size: 12, color: Colors.grey),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          child['className'],
                                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (child['childCode'] != null && child['childCode'].toString().isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 24, top: 2),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.qr_code, size: 12, color: Colors.grey),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Code: ${child['childCode']}',
                                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          )).toList(),
                                        ),
                                  
                                  // Date d'inscription
                                  if (parent['createdAt'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '📅 Inscription: ${_formatDate(parent['createdAt'])}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '-';
    }
  }
}