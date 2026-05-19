// lib/screens/teacher/teacher_events_screen.dart
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:my_school_frontend/models/event_model.dart';
import 'teacher_add_event_screen.dart';
import 'teacher_event_details_screen.dart';

class TeacherEventsScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String className;

  const TeacherEventsScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.className,
  });

  @override
  State<TeacherEventsScreen> createState() => _TeacherEventsScreenState();
}

class _TeacherEventsScreenState extends State<TeacherEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EventModel> _events = [];
  bool _isLoading = true;
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

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getTeacherEvents(
        className: widget.className,
        teacherId: widget.teacherId,
      );
      
      if (result['success'] && mounted) {
        final List<dynamic> eventsData = result['events'] ?? [];
        
        final List<EventModel> loadedEvents = [];
        for (var event in eventsData) {
          if (event['teacherId'] == widget.teacherId) {
            loadedEvents.add(EventModel.fromJson(event));
          }
        }
        
        setState(() {
          _events = loadedEvents;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Erreur chargement événements: $e');
      setState(() => _isLoading = false);
    }
  }

  // Événements en attente (date future)
  List<EventModel> _getPendingEvents() {
    final now = DateTime.now();
    return _events.where((e) => 
      e.status == 'pending' && e.date.isAfter(now)
    ).toList();
  }

  // Événements historiques (date passée)
  List<EventModel> _getHistoryEvents() {
    final now = DateTime.now();
    return _events.where((e) => 
      e.date.isBefore(now) || e.status == 'completed'
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pendingEvents = _getPendingEvents();
    final historyEvents = _getHistoryEvents();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherAddEventScreen(
                teacherId: widget.teacherId,
                teacherName: widget.teacherName,
                className: widget.className,
              ),
            ),
          );
          if (result == true) {
            _loadEvents();
          }
        },
        backgroundColor: const Color(0xFF0288D1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: const Text(
                '📅 ÉVÉNEMENTS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF01579B),
                ),
              ),
            ),
            
            // Tab selector (À venir / Historique)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  _buildTab('📅 À venir (${pendingEvents.length})', pendingEvents.length, 0),
                  _buildTab('📜 Historique (${historyEvents.length})', historyEvents.length, 1),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Liste des événements
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEventsList(pendingEvents, true),
                        _buildEventsList(historyEvents, false),
                      ],
                    ),
            ),
          ],
        ),
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

  Widget _buildEventsList(List<EventModel> events, bool isPending) {
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
              isPending ? 'Aucun événement à venir' : 'Aucun événement dans l\'historique',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            if (isPending)
              Text(
                'Appuyez sur + pour créer',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isEventPast = event.date.isBefore(DateTime.now());
        final statusColor = isEventPast ? Colors.grey : Colors.orange;
        final statusText = isEventPast ? 'Terminé' : 'À venir';
        final statusIcon = isEventPast ? Icons.done_all : Icons.pending;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherEventDetailsScreen(
                    event: event,
                    className: widget.className,
                    teacherId: widget.teacherId,
                    teacherName: widget.teacherName,
                  ),
                ),
              ).then((_) => _loadEvents());
            },
            borderRadius: BorderRadius.circular(16),
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
                              event.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  '${event.date.day}/${event.date.month}/${event.date.year}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            if (event.responseDeadline != null)
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Réponse avant: ${event.responseDeadline!.day}/${event.responseDeadline!.month}/${event.responseDeadline!.year}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(fontSize: 11, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${event.studentResponses.length} élèves',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '${event.acceptedCount} acceptés',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.cancel, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        '${event.rejectedCount} refusés',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}