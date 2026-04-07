import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';

class AdminStatsScreen extends StatefulWidget {
  final String adminEmail;

  const AdminStatsScreen({super.key, required this.adminEmail});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getDashboardStats();
      
      if (result['success']) {
        setState(() {
          _stats = result['stats'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 STATISTIQUES',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF01579B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Répartition des utilisateurs
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                        const Text(
                          '📈 RÉPARTITION DES UTILISATEURS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('Enseignants', '${_stats['totalTeachers'] ?? 0}'),
                        _buildStatRow('Parents', '${_stats['totalParents'] ?? 0}'),
                        _buildStatRow('Élèves', '${_stats['totalStudents'] ?? 0}'),
                        const Divider(height: 24),
                        _buildStatRow('Total', '${(_stats['totalTeachers'] ?? 0) + (_stats['totalParents'] ?? 0) + (_stats['totalStudents'] ?? 0)}', isTotal: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Par classe
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                        const Text(
                          '📊 PAR CLASSE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...(_stats['classes'] as List? ?? []).map((c) => 
                          _buildClassRow(c['name'], '${c['studentCount']}', '${c['studentCount']}')
                        ).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Nombre d'enfants par parent
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                        const Text(
                          '📊 ENFANTS PAR PARENT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('1 enfant', '${_stats['parentsStats']?['oneChild'] ?? 0} parents'),
                        _buildStatRow('2 enfants', '${_stats['parentsStats']?['twoChildren'] ?? 0} parents'),
                        _buildStatRow('3 enfants ou plus', '${_stats['parentsStats']?['threePlusChildren'] ?? 0} parents'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bouton export
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('EXPORTER EN PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF0288D1) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassRow(String className, String effectif, String parents) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              className,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Effectif: $effectif'),
                Text(
                  'Parents: $parents',
                  style: const TextStyle(color: Color(0xFF4CAF9F)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}