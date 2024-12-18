import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateStudentProgress extends StatefulWidget {
  const UpdateStudentProgress({super.key});

  @override
  State<UpdateStudentProgress> createState() => _UpdateStudentProgressState();
}

class _UpdateStudentProgressState extends State<UpdateStudentProgress> {
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  String? _selectedMonth;
  String? _selectedStudent;
  final TextEditingController _examController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _examController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _addStudentProgress() async {
    if (_selectedMonth == null ||
        _selectedStudent == null ||
        _examController.text.isEmpty ||
        _gradeController.text.isEmpty) {
      _showErrorSnackBar('Please fill all fields');
      return;
    }

    // Validate grade
  final validGrades = ['A', 'B', 'C', 'D', 'E'];
  if (!validGrades.contains(_gradeController.text.toUpperCase())) {
    _showErrorSnackBar('Grade must be A, B, C, D, or E');
    return;
  }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(_selectedStudent)
          .collection('progress')
          .add({
        'month': _selectedMonth,
        'exam': _examController.text,
        'grade': _gradeController.text.toUpperCase(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      _resetForm();
      _showSuccessSnackBar('Progress added successfully');
    } catch (e) {
      _showErrorSnackBar('Error adding progress: $e');
    }
    setState(() => _isLoading = false);
  }

  void _resetForm() {
    _examController.clear();
    _gradeController.clear();
    setState(() {
      _selectedMonth = null;
    });
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _updateProgress(String docId) async {
    if (_selectedMonth == null ||
        _examController.text.isEmpty ||
        _gradeController.text.isEmpty) {
      _showErrorSnackBar('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(_selectedStudent)
          .collection('progress')
          .doc(docId)
          .update({
        'month': _selectedMonth,
        'exam': _examController.text,
        'grade': _gradeController.text.toUpperCase(),
        'lastModified': FieldValue.serverTimestamp(),
      });
      _showSuccessSnackBar('Progress updated successfully');
    } catch (e) {
      _showErrorSnackBar('Error updating progress: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteProgress(String docId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this progress entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() => _isLoading = true);
                try {
                  await FirebaseFirestore.instance
                      .collection('students')
                      .doc(_selectedStudent)
                      .collection('progress')
                      .doc(docId)
                      .delete();
                  _showSuccessSnackBar('Progress deleted successfully');
                } catch (e) {
                  _showErrorSnackBar('Error deleting progress: $e');
                }
                setState(() => _isLoading = false);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(String docId, String exam, String grade, String month) {
    _examController.text = exam;
    _gradeController.text = grade;
    _selectedMonth = month;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Edit Progress',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Month',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                value: _selectedMonth,
                items: _months.map((month) {
                  return DropdownMenuItem(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedMonth = value);
                },
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _examController,
                decoration: InputDecoration(
                  labelText: 'Exam Name',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _gradeController,
                decoration: InputDecoration(
                  labelText: 'Grade',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) {
                              if (!RegExp(r'^[A-E]$').hasMatch(value)) {
                                _showErrorSnackBar('Grade must be only A, B, C, D, or E');
                              }
                            },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateProgress(docId);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA), 
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        title: const Text('Student Progress Tracker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFB2DFDB), // Light teal
            Color(0xFFE0F7FA), 
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Progress Entry',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('students')
                                .where('isApproved', isEqualTo: true)
                                .orderBy('name')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const LinearProgressIndicator();
                              }
                              final students = snapshot.data!.docs;
                              return DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Select Student',
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                value: _selectedStudent,
                                items: students.map((student) {
                                  return DropdownMenuItem(
                                    value: student.id,
                                    child: Text(student['name']),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedStudent = value);
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Select Month',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            value: _selectedMonth,
                            items: _months.map((month) {
                              return DropdownMenuItem(
                                value: month,
                                child: Text(month),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedMonth = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _examController,
                            decoration: InputDecoration(
                              labelText: 'Exam Name',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _gradeController,
                            decoration: InputDecoration(
                              labelText: 'Grade',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            onChanged: (value) {
                              if (!RegExp(r'^[A-Ea-e]$').hasMatch(value)) {
                                _showErrorSnackBar('Grade must be only A, B, C, D, or E');
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _addStudentProgress,
                              icon: const Icon(Icons.add, color: Colors.white,),
                              label: const Text('Add Progress', style: TextStyle(color: Colors.white),),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_selectedStudent != null)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Progress History',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 400,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('students')
                                  .doc(_selectedStudent)
                                  .collection('progress')
                                  .orderBy('timestamp', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final progressDocs = snapshot.data!.docs;

                                if (progressDocs.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No progress entries yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: progressDocs.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final progressData = progressDocs[index];
                                    return Card(
                                      elevation: 2,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          child: Text(
                                            progressData['month']
                                                .substring(0, 1),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          progressData['exam'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${progressData['month']} - Grade: ${progressData['grade']}',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () => _showEditDialog(
                                                progressData.id,
                                                progressData['exam'],
                                                progressData['grade'],
                                                progressData['month'],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  _deleteProgress(progressData.id),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}