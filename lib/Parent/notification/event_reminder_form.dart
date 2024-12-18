import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class EventReminderForm extends StatefulWidget {
  @override
  _EventReminderFormState createState() => _EventReminderFormState();
}

class _EventReminderFormState extends State<EventReminderForm> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getEventColor(DateTime date) {
    final daysUntil = date.difference(DateTime.now()).inDays;
    if (daysUntil <= 3) return Colors.red.withOpacity(0.8);
    if (daysUntil <= 7) return Colors.orange.withOpacity(0.8);
    return Colors.green.withOpacity(0.8);
  }

  Stream<QuerySnapshot> _getEventStream() {
    return FirebaseFirestore.instance
        .collection('special_event')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
        .orderBy('date')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Event Reminders',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
            ),
          ),
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _buildListView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search events...',
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.grey.shade600),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
      ),
    );
  }

  Widget _buildListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getEventStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming events',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        var filteredDocs = snapshot.data!.docs.where((doc) {
          final title = (doc['title'] as String? ?? '').toLowerCase();
          final description = (doc['description'] as String? ?? '').toLowerCase();
          return title.contains(_searchQuery) || description.contains(_searchQuery);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final event = filteredDocs[index];
            return _buildEventCard(event);
          },
        );
      },
    );
  }

  Widget _buildEventCard(DocumentSnapshot event) {
    final timestamp = event['date'] as Timestamp?;
    final eventDate = timestamp?.toDate() ?? DateTime.now();
    final formattedDate = timestamp != null
        ? DateFormat('EEEE, d MMMM y').format(timestamp.toDate())
        : 'No Date';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _showEventDetails(event),
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getEventColor(eventDate),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event['description'] ?? 'No Description',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }

  void _showEventDetails(DocumentSnapshot event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailsPage(event: event),
      ),
    );
  }
}

class EventDetailsPage extends StatelessWidget {
  final DocumentSnapshot event;

  const EventDetailsPage({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timestamp = event['date'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('EEEE, d MMMM y').format(timestamp.toDate())
        : 'No Date';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Event Details',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
            ),
          ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  //color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        event['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis, // Avoid overflow
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 20, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event['description'] ?? 'No Description',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                        height: 1.5,
                      ),
                      overflow: TextOverflow.ellipsis, // Avoid overflow
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