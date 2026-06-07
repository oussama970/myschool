// lib/screens/parent/parent_events_screen.dart
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/models/child_model.dart';

class ParentEventsScreen extends StatefulWidget {
  final ChildModel? selectedChild;
  final String parentName;
  final VoidCallback? onResponseChanged;

  const ParentEventsScreen({
    super.key,
    this.selectedChild,
    required this.parentName,
    this.onResponseChanged,
  });

  @override
  State<ParentEventsScreen> createState() => _ParentEventsScreenState();
}

class _ParentEventsScreenState extends State<ParentEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  Map<String, bool> _isSubmitting = {};
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ParentEventsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChild?.id != widget.selectedChild?.id) {
      _loadEvents();
    }
  }

  //  Vérifier si la date limite est dépassée
  bool _isResponseDeadlinePassed(String? deadlineString) {
    if (deadlineString == null || deadlineString.isEmpty) return false;
    try {
      final deadline = DateTime.parse(deadlineString);
      return deadline.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  //  Compter les événements en attente valides (calculé en temps réel)
  int _getPendingEventsCount() {
    if (_events.isEmpty) return 0;
    
    final now = DateTime.now();
    int count = 0;
    
    for (var event in _events) {
      final myResponse = event['myResponse'] ?? 'pending';
      
      // Ignorer si déjà répondu
      if (myResponse != 'pending') continue;
      
      // Vérifier la date limite
      final responseDeadline = event['responseDeadline'];
      if (responseDeadline != null && responseDeadline.toString().isNotEmpty) {
        try {
          final deadline = DateTime.parse(responseDeadline.toString());
          if (deadline.isBefore(now)) continue; // Délai dépassé
        } catch (e) {
          // Si erreur de parsing, on considère que c'est valide
        }
      }
      count++;
    }
    
    return count;
  }

  //  Compter les événements historiques
  int _getHistoryEventsCount() {
    if (_events.isEmpty) return 0;
    
    final now = DateTime.now();
    int count = 0;
    
    for (var event in _events) {
      final myResponse = event['myResponse'] ?? 'pending';
      
      // Déjà répondu
      if (myResponse != 'pending') {
        count++;
        continue;
      }
      
      // En attente mais date limite dépassée
      final responseDeadline = event['responseDeadline'];
      if (responseDeadline != null && responseDeadline.toString().isNotEmpty) {
        try {
          final deadline = DateTime.parse(responseDeadline.toString());
          if (deadline.isBefore(now)) {
            count++;
          }
        } catch (e) {}
      }
    }
    
    return count;
  }

  Future<void> _loadEvents() async {
    if (widget.selectedChild == null) {
      setState(() {
        _events = [];
        _isLoading = false;
      });
      widget.onResponseChanged?.call();
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      print('📅 Chargement des événements pour: ${widget.selectedChild!.fullName}');
      
      final result = await ApiService.getParentEvents(widget.selectedChild!.id);
      
      print('========== DÉBOGAGE ==========');
      print('Succès: ${result['success']}');
      print('Événements reçus: ${result['events']?.length ?? 0}');
      
      if (mounted) {
        List<Map<String, dynamic>> loadedEvents = List<Map<String, dynamic>>.from(result['events'] ?? []);
        
        setState(() {
          _events = loadedEvents;
          _isLoading = false;
        });
        
        print('📊 À valider: ${_getPendingEventsCount()}');
        print('📊 Historique: ${_getHistoryEventsCount()}');
        
        //  Notifier le parent pour mettre à jour le badge
        widget.onResponseChanged?.call();
      }
    } catch (e) {
      print('❌ Erreur: $e');
      setState(() {
        _events = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _respondToEvent(String eventId, String response, String eventTitle) async {
    if (widget.selectedChild == null) return;
    
    setState(() => _isSubmitting[eventId] = true);
    try {
      final result = await ApiService.respondToEvent(
        eventId: eventId,
        studentId: widget.selectedChild!.id,
        studentName: widget.selectedChild!.fullName,
        response: response,
      );
      
      if (result['success'] && mounted) {
        await _loadEvents();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${response == 'accepted' ? 'Accepté' : 'Refusé'} : $eventTitle'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting[eventId] = false);
    }
  }

  void _showConfirmDialog(String eventId, String eventTitle, String response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              response == 'accepted' ? Icons.check_circle : Icons.cancel,
              color: response == 'accepted' ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(response == 'accepted' ? 'Accepter' : 'Refuser'),
          ],
        ),
        content: Text(
          'Voulez-vous ${response == 'accepted' ? 'accepter' : 'refuser'} la participation de ${widget.selectedChild!.fullName} à "$eventTitle" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _respondToEvent(eventId, response, eventTitle);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: response == 'accepted' ? Colors.green : Colors.red,
            ),
            child: Text(response == 'accepted' ? 'ACCEPTER' : 'REFUSER'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    //  Recalculer les compteurs à chaque build
    final pendingCount = _getPendingEventsCount();
    final historyCount = _getHistoryEventsCount();

    if (widget.selectedChild == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Événements'),
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

    // Filtrer les événements pour les listes
    final now = DateTime.now();
    
    final pendingEvents = _events.where((event) {
      final myResponse = event['myResponse'] ?? 'pending';
      if (myResponse != 'pending') return false;
      
      final responseDeadline = event['responseDeadline'];
      if (responseDeadline != null && responseDeadline.toString().isNotEmpty) {
        try {
          final deadline = DateTime.parse(responseDeadline.toString());
          return !deadline.isBefore(now);
        } catch (e) {
          return true;
        }
      }
      return true;
    }).toList();
    
    final historyEvents = _events.where((event) {
      final myResponse = event['myResponse'] ?? 'pending';
      if (myResponse != 'pending') return true;
      
      final responseDeadline = event['responseDeadline'];
      if (responseDeadline != null && responseDeadline.toString().isNotEmpty) {
        try {
          final deadline = DateTime.parse(responseDeadline.toString());
          return deadline.isBefore(now);
        } catch (e) {
          return false;
        }
      }
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Événements - ${widget.selectedChild!.fullName}'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = 0;
                              _tabController.animateTo(0);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0 ? const Color(0xFF0288D1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                '📝 À valider ($pendingCount)',
                                style: TextStyle(
                                  color: _selectedTabIndex == 0 ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = 1;
                              _tabController.animateTo(1);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 1 ? const Color(0xFF0288D1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                '📜 Historique ($historyCount)',
                                style: TextStyle(
                                  color: _selectedTabIndex == 1 ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      _buildEventsList(pendingEvents, true),
                      _buildEventsList(historyEvents, false),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEventsList(List<Map<String, dynamic>> events, bool isPending) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.event_available : Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'Aucun événement à valider' : 'Aucun événement dans l\'historique',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final date = DateTime.parse(event['date']);
          final myResponse = event['myResponse'] ?? 'pending';
          final isSubmitting = _isSubmitting[event['_id']] ?? false;
          final responseDeadline = event['responseDeadline'];
          final isDeadlinePassed = _isResponseDeadlinePassed(responseDeadline);
          
          // Afficher les boutons seulement si en attente et délai non dépassé
          final bool showButtons = isPending && !isDeadlinePassed && myResponse == 'pending';
          
          Color statusColor;
          IconData statusIcon;
          String statusText;
          
          if (myResponse == 'accepted') {
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            statusText = '✅ Participation acceptée';
          } else if (myResponse == 'rejected') {
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            statusText = '❌ Participation refusée';
          } else if (isDeadlinePassed) {
            statusColor = Colors.grey;
            statusIcon = Icons.timer_off;
            statusText = '⏰ Délai dépassé';
          } else {
            statusColor = Colors.orange;
            statusIcon = Icons.pending;
            statusText = '⏳ En attente';
          }

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
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] ?? 'Sans titre',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(_formatDate(date), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (event['description'] != null && event['description'].isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(event['description'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                  if (showButtons) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSubmitting ? null : () => _showConfirmDialog(event['_id'], event['title'], 'rejected'),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('REFUSER'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isSubmitting ? null : () => _showConfirmDialog(event['_id'], event['title'], 'accepted'),
                            icon: isSubmitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.check, size: 18),
                            label: Text(isSubmitting ? 'Envoi...' : 'ACCEPTER'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}