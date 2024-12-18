import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';

class EditStudentDetailsSection extends StatefulWidget {
  const EditStudentDetailsSection({super.key});

  @override
  State<EditStudentDetailsSection> createState() => _EditStudentDetailsSectionState();
}

class _EditStudentDetailsSectionState extends State<EditStudentDetailsSection> {
  String? _selectedStudentId;
  Map<String, dynamic>? _selectedStudent;
  final TextEditingController _healthStatusController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _healthStatusController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveHealthStatus() async {
    if (_selectedStudentId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(_selectedStudentId)
          .update({'healthStatus': _healthStatusController.text});

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Health status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      _fetchStudentDetails(_selectedStudentId!);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating health status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchStudentDetails(String studentId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();
          
      setState(() {
        _selectedStudent = snapshot.data() as Map<String, dynamic>?;
        _healthStatusController.text = _selectedStudent?['healthStatus'] ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching student details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchApprovedStudents() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('isApproved', isEqualTo: true)
          .orderBy('name')  // Sort by name
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'],
        'profile_image': doc['profile_image'],
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Widget _buildStudentDetails() {
  return Container(
    //color: Colors.grey[100], // Background color for the page
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Profile Image Section
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, size: 60, color: Colors.grey),
                ),
                if (_selectedStudent != null && _selectedStudent!['profile_image'] != null)
                  GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageView(
                      imageUrl: _selectedStudent!['profile_image'],
                    ),
                  ),
                );
              },
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(_selectedStudent!['profile_image']),
                      onBackgroundImageError: (e, _) {},
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Student Information Section
          const Text(
            'Student Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const Divider(color: Colors.blueGrey),

          if (_selectedStudent != null) ...[
            _buildDetailRow('Name', _selectedStudent!['name'] ?? 'N/A'),
            _buildDetailRow('Birthday', _selectedStudent!['date_of_birth'] ?? 'N/A'),
            _buildDetailRow('Gender', _selectedStudent!['gender'] ?? 'N/A'),
            _buildDetailRow('Address', _selectedStudent!['address'] ?? 'N/A'),
            _buildDetailRow('Emergency Contact', _selectedStudent!['emergencyContact'] ?? 'N/A'),
            _buildDetailRow('Allergic Food', _selectedStudent!['allergies'] ?? 'None'),
          ] else
            const Center(
              child: Text(
                'No student selected.',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.blueGrey,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Health Status Section
          if (_selectedStudent != null) ...[
            const Text(
              'Health Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const Divider(color: Colors.blueGrey),
            const SizedBox(height: 8),
            TextField(
              controller: _healthStatusController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter health status',
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _saveHealthStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const  Text('Update Status'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildDetailRow(String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA), // Lighter teal,
      appBar: AppBar(
        title: const Text('Student Details'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: const Color.fromARGB(255, 246, 246, 246),
        elevation: 2,
      ),
      body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFB2DFDB), // Light teal
            Color(0xFFE0F7FA), // Lighter teal
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchApprovedStudents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
        
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)),
              );
            }
        
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No approved students found.'));
            }
        
            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Student Selector
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Select Student',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            hint: const Text('Choose a student'),
                            value: _selectedStudentId,
                            items: snapshot.data!.map((student) {
                              return DropdownMenuItem<String>(
                                value: student['id'],
                                child: Text(student['name']),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedStudentId = newValue;
                                  _selectedStudent = null; // Clear current details
                                });
                                _fetchStudentDetails(newValue);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
        
                  // Student Details Sectionf
                  _buildStudentDetails(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Profile Image', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      ),
    );
  }
}