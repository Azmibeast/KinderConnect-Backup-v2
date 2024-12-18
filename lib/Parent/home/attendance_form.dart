import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceForm extends StatefulWidget {
  final String parentId;

  const AttendanceForm({Key? key, required this.parentId}) : super(key: key);

  @override
  _AttendanceFormState createState() => _AttendanceFormState();
}

class _AttendanceFormState extends State<AttendanceForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  String? _attendanceStatus;
  String? _selectedChildId;
  String? _selectedFileName;
  PlatformFile? _attachedFile;

  List<Map<String, dynamic>> _childrenList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('parent_id', isEqualTo: widget.parentId)
          .where('isApproved', isEqualTo: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _childrenList = snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'name': doc['name'] ?? 'Unnamed Child',
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B6FC1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF560063),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _attachedFile = result.files.first;
        _selectedFileName = _attachedFile!.name;
      });
    }
  }

  Future<void> _submitAttendance() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _attendanceStatus != null) {
      try {
        await FirebaseFirestore.instance.collection('absent_notice').add({
          'childId': _selectedChildId,
          'date': _selectedDate,
          'attendanceStatus': _attendanceStatus,
          'attachment': _attachedFile?.name ?? 'No attachment',
          'isValidated': false,
        });

        _showSuccessDialog();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      String errorMessage = '';
      if (_selectedChildId == null) {
        errorMessage = 'Please select a child';
      } 
      else if (_selectedDate == null) {
        errorMessage = 'Please select a date';
      }
      else if (_attendanceStatus == null) {
        errorMessage = 'Please select a reason for absence';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B6FC1), Color(0xFF8C4D97)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 60,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Success!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Absence notice has been issued to the teacher!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF8B6FC1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8B6FC1), Color(0xFF8C4D97)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'Notify Absence',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Form Content
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: Container(
                      color: Colors.white,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_isLoading)
                                  const Center(child: CircularProgressIndicator())
                                else if (_childrenList.isEmpty)
                                    Center(
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
                                  else ...[
                                    // Child Selector
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Select Child',
                                      prefixIcon: const Icon(Icons.child_care),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select child name';
                                      }
                                      return null;
                                    },
                                    value: _selectedChildId,
                                    isExpanded: true,
                                    items: _childrenList.map((child) {
                                      return DropdownMenuItem<String>(
                                        value: child['id'],
                                        child: Text(child['name']),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedChildId = newValue;
                                      });
                                    },
                                  ),
                                
                                const SizedBox(height: 20),

                                // Date Selection
                                InkWell(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(15),
                                      color: Colors.grey[100],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today),
                                        const SizedBox(width: 10),
                                        Text(
                                          _selectedDate == null
                                              ? 'Select Date'
                                              : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                                          style: TextStyle(
                                            color: _selectedDate == null
                                                ? Colors.grey[600]
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Attendance Status
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Reason for Absence',
                                    prefixIcon: const Icon(Icons.error_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                  ),
                                  value: _attendanceStatus,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Sick',
                                      child: Text('Sick'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Family Emergency',
                                      child: Text('Family Emergency'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Other',
                                      child: Text('Other'),
                                    ),
                                  ],
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _attendanceStatus = newValue;
                                    });
                                  },
                                ),

                                const SizedBox(height: 20),

                                // File Attachment
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.grey[100],
                                  ),
                                  child: Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _pickFile,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF8B6FC1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                        ),
                                        icon: const Icon(Icons.attach_file, color: Colors.white,),
                                        label: const Text('Attach File', style: TextStyle(color: Colors.white),),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _selectedFileName ?? 'No file selected',
                                          style: TextStyle(
                                            color: _selectedFileName != null
                                                ? Colors.green
                                                : Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Submit Button
                                ElevatedButton(
                                  onPressed: _submitAttendance,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B6FC1),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Submit Absence Notice',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white
                                    ),
                                  ),
                                ),
    ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}