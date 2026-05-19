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

  Future<void> _loadEvents() async {
    if (widget.selectedChild == null) {
      setState(() {
        _events = [];
        _isLoading = false;
      });
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      print('📅 Chargement des événements pour: ${widget.selectedChild!.fullName}');
      
      final result = await ApiService.getParentEvents(widget.selectedChild!.id);
      
      if (mounted) {
        List<Map<String, dynamic>> loadedEvents = List<Map<String, dynamic>>.from(result['events'] ?? []);
        
        // Traiter les événements pour marquer ceux dont le délai est dépassé comme "refusés"
        final now = DateTime.now();
        for (var i = 0; i < loadedEvents.length; i++) {
          final event = loadedEvents[i];
          final myResponse = event['myResponse'] ?? 'pending';
          final responseDeadline = event['responseDeadline'];
          
          // Si l'événement est encore en attente ET que la date limite est dépassée
          if (myResponse == 'pending' && responseDeadline != null && responseDeadline.toString().isNotEmpty) {
            try {
              final deadline = DateTime.parse(responseDeadline.toString());
              if (deadline.isBefore(now)) {
                // Marquer automatiquement comme refusé
                loadedEvents[i]['myResponse'] = 'rejected';
                loadedEvents[i]['autoRejected'] = true; // Marqueur pour indiquer que c'est automatique
                print('⏰ Événement "${event['title']}" marqué comme refusé (délai dépassé)');
              }
            } catch (e) {
              print('Erreur parsing date limite: $e');
            }
          }
        }
        
        setState(() {
          _events = loadedEvents;
          _isLoading = false;
        });
        
        print('✅ ${_events.length} événements trouvés');
      } else {
        setState(() => _isLoading = false);
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
        widget.onResponseChanged?.call();
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

  bool _isEventPast(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  bool _isResponseDeadlinePassed(String? deadlineString) {
    if (deadlineString == null || deadlineString.isEmpty) return false;
    try {
      final deadline = DateTime.parse(deadlineString);
      return deadline.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrer les événements:
    // - À valider: événements en attente ET date limite non dépassée
    // - Historique: événements avec réponse (accepté/refusé) OU date limite dépassée
    final now = DateTime.now();
    
    final pendingEvents = _events.where((e) {
      final myResponse = e['myResponse'] ?? 'pending';
      final responseDeadline = e['responseDeadline'];
      
      if (myResponse != 'pending') return false;
      
      // Si pas de date limite, reste dans "À valider"
      if (responseDeadline == null || responseDeadline.toString().isEmpty) return true;
      
      // Vérifier si la date limite est dépassée
      try {
        final deadline = DateTime.parse(responseDeadline.toString());
        return !deadline.isBefore(now);
      } catch (e) {
        return true;
      }
    }).toList();
    
    final historyEvents = _events.where((e) {
      final myResponse = e['myResponse'] ?? 'pending';
      if (myResponse != 'pending') return true;
      
      // Les événements en attente avec date limite dépassée vont dans l'historique
      final responseDeadline = e['responseDeadline'];
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
                      _buildTab('📝 À valider (${pendingEvents.length})', pendingEvents.length, 0),
                      _buildTab('📜 Historique (${historyEvents.length})', historyEvents.length, 1),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
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

  Widget _buildTab(String text, int count, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
            _tabController.animateTo(index);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0288D1) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
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
            const SizedBox(height: 8),
            if (isPending)
              Text(
                'Pour ${widget.selectedChild!.fullName}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
          final isAutoRejected = event['autoRejected'] == true;
          
          // Déterminer si on affiche les boutons
          final bool showButtons = isPending && !isDeadlinePassed && myResponse == 'pending';
          
          // Déterminer la couleur et l'icône du statut
          Color statusColor;
          IconData statusIcon;
          String statusText;
          
          if (myResponse == 'accepted') {
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            statusText = '✅ Participation acceptée';
          } else if (myResponse == 'rejected') {
            if (isAutoRejected) {
              statusColor = Colors.grey;
              statusIcon = Icons.timer_off;
              statusText = '⏰ Délai de réponse dépassé ';
            } else {
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
              statusText = '❌ Participation refusée';
            }
          } else {
            statusColor = const Color(0xFF0288D1);
            statusIcon = Icons.pending;
            statusText = '⏳ En attente de réponse';
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
                        child: Icon(
                          statusIcon,
                          color: statusColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] ?? 'Sans titre',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(date),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            if (responseDeadline != null && responseDeadline.toString().isNotEmpty && !isDeadlinePassed)
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 12, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Réponse avant: ${_formatDate(DateTime.parse(responseDeadline.toString()))}',
                                    style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                                  ),
                                ],
                              ),
                            // Badge de statut compact
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 12, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (event['description'] != null && event['description'].isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      event['description'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                  if (showButtons) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSubmitting
                                ? null
                                : () => _showConfirmDialog(event['_id'], event['title'], 'rejected'),
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
                            onPressed: isSubmitting
                                ? null
                                : () => _showConfirmDialog(event['_id'], event['title'], 'accepted'),
                            icon: isSubmitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.check, size: 18),
                            label: Text(isSubmitting ? 'Envoi...' : 'ACCEPTER'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
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