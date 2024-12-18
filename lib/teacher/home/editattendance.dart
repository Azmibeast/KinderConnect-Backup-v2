import 'package:KinderConnect/teacher/home/validateattendanceform.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditAttendance extends StatefulWidget {
  const EditAttendance({super.key});

  @override
  State<EditAttendance> createState() => _EditAttendanceState();
}

class _EditAttendanceState extends State<EditAttendance> {
  final TextEditingController _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);
    _fetchAttendanceRecords();
  }

  Future<void> _fetchAttendanceRecords() async {
    setState(() => _isLoading = true);
    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      setState(() {
        _attendanceRecords = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'],
            'isPresent': data['isPresent'],
            'studentId': data['studentId'],
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to fetch attendance records');
    }
  }

  Future<void> _updateAttendance(String docId, bool isPresent) async {
  try {
    // Update Firestore
    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(docId)
        .update({'isPresent': isPresent});
    
    // Update local list
    setState(() {
      final recordIndex =
          _attendanceRecords.indexWhere((record) => record['id'] == docId);
      if (recordIndex != -1) {
        _attendanceRecords[recordIndex]['isPresent'] = isPresent;
      }
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isPresent ? 'Marked as present' : 'Marked as absent'),
        backgroundColor: isPresent ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
  } catch (e) {
    _showErrorDialog('Failed to update attendance');
  }
}


  Future<void> _deleteAttendance(String docId) async {
  if (!mounted) return; // Check if the widget is mounted
  final currentContext = context; // Save the current context

  try {
    await showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this attendance record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // Use dialog-specific context
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close the dialog
              await FirebaseFirestore.instance
                  .collection('attendance')
                  .doc(docId)
                  .delete();

              if (mounted) {
                setState(() {
                  _attendanceRecords.removeWhere((record) => record['id'] == docId);
                });
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  const SnackBar(content: Text('Attendance record deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  } catch (e) {
    if (mounted) {
      _showErrorDialog('Failed to delete attendance record');
    }
  }
}


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      fieldHintText: 'dd/mm/yyyy',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('EEEE, d MMMM , yyyy').format(_selectedDate);
      });
      _fetchAttendanceRecords();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 2,
      ),
      body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 195, 246, 192), // Light blue
            Color.fromARGB(255, 228, 234, 240), // Dodger blue
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
        child: RefreshIndicator(
          onRefresh: _fetchAttendanceRecords,
          child: FadeInUp(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            "Edit Attendance",
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                _dateController.text,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _attendanceRecords.isEmpty
                            ? _buildEmptyState()
                            : _buildAttendanceList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ValidateAttendanceForm(),
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 7, 116, 11),
        icon: const Icon(Icons.add, color: Colors.white,),
        label: const Text('New Attendance',style: TextStyle(color: Colors.white),),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'for ${DateFormat('EEEE, d MMMM , yyyy').format(_selectedDate)}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = _attendanceRecords[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: record['isPresent'] ? Colors.green : Colors.red,
              child: Icon(
                record['isPresent'] ? Icons.check : Icons.close,
                color: Colors.white,
              ),
            ),
            title: Text(
              record['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              record['isPresent'] ? 'Present' : 'Absent',
              style: TextStyle(
                color: record['isPresent'] ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: record['isPresent'],
                  onChanged: (value) => _updateAttendance(record['id'], value),
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: () => _deleteAttendance(record['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}