import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';

class StudentApplication {
  final String id;
  final String name;
  final String dateOfBirth;
  final String gender;
  final String address;
  final String? profileImage;
  bool isApproved;
  String? reviewNotes;
  String status;

  StudentApplication({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    this.profileImage,
    this.isApproved = false,
    this.reviewNotes,
    this.status = 'pending',
  });

  factory StudentApplication.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StudentApplication(
      id: doc.id,
      name: data['name'] ?? '',
      dateOfBirth: data['date_of_birth'] ?? '',
      gender: data['gender'] ?? '',
      address: data['address'] ?? '',
      profileImage: data['profile_image'],
      isApproved: data['isApproved'] ?? false,
      reviewNotes: data['review_notes'],
      status: data['status'] ?? 'pending',
    );
  }
}

class NewStudentNotification extends StatefulWidget {
  const NewStudentNotification({Key? key}) : super(key: key);

  @override
  State<NewStudentNotification> createState() => _NewStudentNotificationState();
}

class _NewStudentNotificationState extends State<NewStudentNotification> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _reviewNotesController = TextEditingController();

  Future<void> updateApplicationStatus(String studentId, String status, String notes) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'status': status,
        'review_notes': notes,
        'isApproved': status == 'approved',
        'reviewed_at': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application ${status.toUpperCase()}'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating application status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReviewDialog(StudentApplication student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Review - ${student.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review Notes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reviewNotesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter your review notes...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _reviewNotesController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_reviewNotesController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add review notes')),
                  );
                  return;
                }
                updateApplicationStatus(
                  student.id,
                  'rejected',
                  _reviewNotesController.text,
                );
                _reviewNotesController.clear();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject', style: TextStyle(color: Colors.white),),
            ),
            ElevatedButton(
              onPressed: () {
                if (_reviewNotesController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add review notes')),
                  );
                  return;
                }
                updateApplicationStatus(
                  student.id,
                  'approved',
                  _reviewNotesController.text,
                );
                _reviewNotesController.clear();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approve',style: TextStyle(color: Colors.white),),
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
        backgroundColor: Colors.orange[100],
        title: const Text('Student Applications', style: TextStyle(fontWeight: FontWeight.w600),),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('students')
            .where('status', isEqualTo: 'pending')
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
                  Image.asset(
                    'assets/images/notfound2.jpg', // Replace with your image path
                    height: 210, // Adjust height as needed
                    width: 210,  // Adjust width as needed
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No pending applications',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
}

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final student = StudentApplication.fromFirestore(
                snapshot.data!.docs[index],
              );

              return Card(
  color: const Color.fromARGB(255, 220, 230, 218),
  margin: const EdgeInsets.only(bottom: 16),
  child: Column(
    children: [
      ListTile(
        leading: GestureDetector(
          onTap: () {
            if (student.profileImage != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Profile Image'),
                      backgroundColor: const Color.fromARGB(255, 249, 208, 255),
                    ),
                    body: PhotoView(
                      imageProvider: NetworkImage(student.profileImage!),
                    ),
                  ),
                ),
              );
            }
          },
          child: CircleAvatar(
            radius: 25,
            backgroundImage: student.profileImage != null
                ? NetworkImage(student.profileImage!)
                : null,
            child: student.profileImage == null
                ? const Icon(Icons.person)
                : null,
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date of Birth: ${student.dateOfBirth}'),
            Text('Gender: ${student.gender}'),
            Text('Address: ${student.address}'),
          ],
        ),
        isThreeLine: true,
      ),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.rate_review),
              label: const Text('Review'),
              onPressed: () => _showReviewDialog(student),
            ),
          ],
        ),
      ),
    ],
  ),
);

            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _reviewNotesController.dispose();
    super.dispose();
  }
}