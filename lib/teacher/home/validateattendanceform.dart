import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ValidateAttendanceForm extends StatefulWidget {
  const ValidateAttendanceForm({Key? key}) : super(key: key);

  @override
  _ValidateAttendanceFormState createState() => _ValidateAttendanceFormState();
}

class _ValidateAttendanceFormState extends State<ValidateAttendanceForm> with SingleTickerProviderStateMixin {
  List<Student> _students = [];
  final TextEditingController _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animationController;
  bool _isLoading = true;
  bool _isDateSelected = false;

  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    //_dateController.text = DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate);
    _fetchApprovedStudents();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _fetchApprovedStudents() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('isApproved', isEqualTo: true)
          .orderBy('name')
          .get();

      setState(() {
        _students = snapshot.docs
            .map((doc) => Student(
                  id: doc.id,
                  name: doc['name'],
                  isPresent: true,
                ))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to fetch students');
    }
  }

  Future<void> _storeAttendance() async {
    if (!_isDateSelected) {
    // Check if date is not selected
    _showErrorDialog('Please select a date before saving attendance.');
    return;
  }
  
  setState(() => _isLoading = true);
  try {
    // Check if attendance for the selected date already exists
    final querySnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('date', isEqualTo: _selectedDate)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Attendance for the date already exists
      _showErrorDialog('Attendance for the selected date has already been recorded.');
    } else {
      // Store attendance if it doesn't exist
      final batch = FirebaseFirestore.instance.batch();
      final attendanceCollection = FirebaseFirestore.instance.collection('attendance');

      for (var student in _students) {
        final docRef = attendanceCollection.doc();
        batch.set(docRef, {
          'studentId': student.id,
          'name': student.name,
          'isPresent': student.isPresent,
          'date': _selectedDate,
          'timestamp': Timestamp.now(),
        });
      }

      await batch.commit();
      _showSuccessDialog();
    }
  } catch (e) {
    _showErrorDialog('Failed to save attendance');
  } finally {
    setState(() => _isLoading = false);
  }
}


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF27C165),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate);
        _isDateSelected = true; // Mark date as selected
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF27C165)),
              SizedBox(width: 10),
              Text('Success'),
            ],
          ),
          content: const Text('Attendance has been successfully saved!'),
          actions: [
            TextButton(
              child: const Text('OK', style: TextStyle(color: Color(0xFF27C165))),
              onPressed: () => {Navigator.of(context).pop(),
              Navigator.of(context).pop(),Navigator.of(context).pop(),}
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 10),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudentCard(Student student, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (index / _students.length) * 0.5,
              ((index + 1) / _students.length) * 0.5,
              curve: Curves.easeOut,
            ),
          )),
          child: child,
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              student.isPresent = !student.isPresent;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: student.isPresent ? const Color(0xFF27C165) : Colors.red,
                  child: Icon(
                    student.isPresent ? Icons.check : Icons.close,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        student.isPresent ? 'Present' : 'Absent',
                        style: TextStyle(
                          color: student.isPresent ? const Color(0xFF27C165) : Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: student.isPresent,
                  onChanged: (bool value) {
                    setState(() {
                      student.isPresent = value;
                    });
                  },
                  activeColor: const Color(0xFF27C165),
                  inactiveThumbColor: Colors.red,
                  inactiveTrackColor: Colors.red.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _animationController.forward();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 195, 246, 192), // Light blue
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF27C165)))
            : Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const Text(
                      "Attendance Record",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Please select date',
                          hintText: 'Click calendar icon to pick date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          //prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF27C165)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit_calendar, color: Color(0xFF27C165)),
                            onPressed: () => _selectDate(context),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) => _buildStudentCard(_students[index], index),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _storeAttendance,
              backgroundColor: const Color(0xFF27C165),
              icon: const Icon(Icons.save),
              label: const Text('Save Attendance'),
            )
          : null,
    );
  }
}

class Student {
  String id;
  String name;
  bool isPresent;

  Student({required this.id, required this.name, this.isPresent = true});
}