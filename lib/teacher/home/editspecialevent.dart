import 'package:KinderConnect/teacher/home/specialeventplan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSpecialEvent extends StatefulWidget {
  const EditSpecialEvent({super.key});

  @override
  State<EditSpecialEvent> createState() => _EditSpecialEventState();
}

class _EditSpecialEventState extends State<EditSpecialEvent> {
  DateTime? _selectedDate;
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: _selectedDate ?? DateTime.now(),
    firstDate: DateTime(2022),
    lastDate: DateTime(2025),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.blue,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      );
    },
  );

  if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });

      // Check if this is called in the edit dialog context
      if (ModalRoute.of(context)?.isActive ?? false) {
        // No changes message only if date is exactly the same
        
      }
    }
  }


  Future<void> _updateEvent(String eventId) async {
    if (_eventTitleController.text.isEmpty ||
        _eventDescriptionController.text.isEmpty ||
        _selectedDate == null) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Validate date is selected before proceeding
      if (_selectedDate == null) {
        _showErrorSnackBar('Please select a date');
        return;
      }

      await FirebaseFirestore.instance.collection('special_event').doc(eventId).update({
        'title': _eventTitleController.text.trim(),
        'description': _eventDescriptionController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate!),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      _showSuccessSnackBar('Event updated successfully');
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Failed to update event: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _deleteEvent(String eventId) async {
    final bool confirm = await _showDeleteConfirmation(context);
    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('special_event').doc(eventId).delete();
      _showSuccessSnackBar('Event deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete event');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openEditDialog(BuildContext context, DocumentSnapshot eventDoc) async {
    setState(() {
      _eventTitleController.text = eventDoc['title'];
      _eventDescriptionController.text = eventDoc['description'];
      _selectedDate = (eventDoc['date'] as Timestamp).toDate();
    });

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit_calendar, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit Event'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _eventTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _eventDescriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Event Description',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setStateInternal) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _selectedDate == null
                                ? 'No Date Selected'
                                : DateFormat('EEEE, d MMMM y').format(_selectedDate!),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _selectDate(context),
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Choose Date'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _updateEvent(eventDoc.id),
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Special Events'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.withOpacity(0.1), Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('special_event')
              .orderBy('date')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_busy, size: 64, color:  Color.fromARGB(255, 0, 0, 0)),
                    const SizedBox(height: 16),
                    Text(
                      'No events available',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final eventDoc = snapshot.data!.docs[index];
                final DateTime eventDate = (eventDoc['date'] as Timestamp).toDate();
                final bool isToday = DateUtils.isSameDay(eventDate, DateTime.now());
                final bool isPast = eventDate.isBefore(DateTime.now());

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isToday
                        ? const BorderSide(color: Colors.blue, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    onTap: () => _openEditDialog(context, eventDoc),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? Colors.blue
                                      : isPast
                                          ? Colors.grey
                                          : Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  DateFormat('MMM d, y').format(eventDate),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _openEditDialog(context, eventDoc),
                                tooltip: 'Edit Event',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteEvent(eventDoc.id),
                                tooltip: 'Delete Event',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            eventDoc['title'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            eventDoc['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PlanSpecialEventForm(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}