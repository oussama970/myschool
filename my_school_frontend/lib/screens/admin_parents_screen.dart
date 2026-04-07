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
      
      if (result['success']) {
        setState(() {
          _parents = result['parents'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
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

          // Barre de recherche
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

          // Liste des parents
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        parent['fullName'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF01579B),
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
                                  const SizedBox(height: 4),
                                  Text(parent['email'] ?? ''),
                                  if (parent['phoneNumber'] != null && parent['phoneNumber'].isNotEmpty)
                                    Text('Tél: ${parent['phoneNumber']}'),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Enfants:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...(parent['children'] as List? ?? []).map((c) => Padding(
                                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                                    child: Text('• ${c['fullName']} (${c['className'] ?? '-'})'),
                                  )),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Inscription: ${parent['createdAt'] != null ? DateTime.parse(parent['createdAt']).toLocal().toString().split(' ')[0] : '-'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
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
}