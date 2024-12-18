import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceDetails extends StatefulWidget {
  final String parentId;
  AttendanceDetails({required this.parentId});

  @override
  State<AttendanceDetails> createState() => _AttendanceDetailsState();
}

class _AttendanceDetailsState extends State<AttendanceDetails> {
  String? _selectedChildId;
  List<DocumentSnapshot> _children = [];
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('parent_id', isEqualTo: widget.parentId)
          .where('isApproved', isEqualTo: true)
          .get();

      setState(() {
        _children = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching children: $e')),
      );
    }
  }

  Future<List<DocumentSnapshot>> _fetchAttendanceRecords() async {
    if (_selectedChildId == null) return [];
    
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('studentId', isEqualTo: _selectedChildId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs;
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          TextButton(
            child: Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF46968A),
              ),
            ),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                setState(() => _selectedMonth = picked);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: DateTime(_selectedMonth.year, _selectedMonth.month).isAfter(DateTime.now())
                ? null
                : () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                      );
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedChildId,
          hint: const Text('Select Child'),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_circle_outlined),
          items: _children.map((child) {
            return DropdownMenuItem<String>(
              value: child.id,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF46968A).withOpacity(0.2),
                    child: Text(
                      child['name'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF46968A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      child['name'],
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedChildId = value),
        ),
      ),
    );
  }

  Widget _buildAttendanceStats(List<DocumentSnapshot> records) {
    int totalDays = records.length;
    int presentDays = records.where((r) => r['isPresent']).length;
    double attendancePercentage = totalDays > 0 ? (presentDays / totalDays) * 100 : 0;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF46968A), const Color(0xFF46968A).withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Days', totalDays.toString()),
              _buildStatItem('Present', presentDays.toString()),
              _buildStatItem('Absent', (totalDays - presentDays).toString()),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: attendancePercentage / 100,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${attendancePercentage.toStringAsFixed(1)}% Attendance',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList(List<DocumentSnapshot> records) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final date = (record['date'] as Timestamp).toDate();
        final formattedDate = DateFormat('EEEE, dd MMMM').format(date);
        final isPresent = record['isPresent'];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: isPresent 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              child: Icon(
                isPresent ? Icons.check : Icons.close,
                color: isPresent ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              formattedDate,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                color: isPresent ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2DFDB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF46968A),
        title: const Text(
          'Attendance Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F2F1),
              Color(0xFFB2DFDB),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _children.isEmpty
              ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 15),
              const Text(
                'You don\'t have any child registered yet!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please register your child first.',
                style: TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildChildSelector(),
                    _buildMonthSelector(),
                    if (_selectedChildId != null)
                      FutureBuilder<List<DocumentSnapshot>>(
                        future: _fetchAttendanceRecords(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'No attendance records found for this month.',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          }
        
                          final records = snapshot.data!;
                          return Column(
                            children: [
                              _buildAttendanceStats(records),
                              _buildAttendanceList(records),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}