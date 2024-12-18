import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentStatus {
  final String id;
  final String name;
  final String dateOfBirth;
  final String gender;
  final String address;
  final String? profileImage;
  final String status;
  final String? reviewNotes;
  final Timestamp? reviewedAt;

  StudentStatus({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    this.profileImage,
    required this.status,
    this.reviewNotes,
    this.reviewedAt,
  });

  factory StudentStatus.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StudentStatus(
      id: doc.id,
      name: data['name'] ?? '',
      dateOfBirth: data['date_of_birth'] ?? '',
      gender: data['gender'] ?? '',
      address: data['address'] ?? '',
      profileImage: data['profile_image'],
      status: data['status'] ?? 'pending',
      reviewNotes: data['review_notes'],
      reviewedAt: data['reviewed_at'] as Timestamp?,
    );
  }
}

class ParentStudentStatusPage extends StatefulWidget {
  final String parentId; // Parent's ID to fetch related students

  const ParentStudentStatusPage({
    Key? key,
    required this.parentId,
  }) : super(key: key);

  @override
  State<ParentStudentStatusPage> createState() => _ParentStudentStatusPageState();
}

class _ParentStudentStatusPageState extends State<ParentStudentStatusPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Children\'s Status'),
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
              colors: [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
            ),
          ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('students')
              .where('parent_id', isEqualTo: widget.parentId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
        
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No student applications found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
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
                final student = StudentStatus.fromFirestore(
                  snapshot.data!.docs[index],
                );
        
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: student.profileImage != null
                              ? NetworkImage(student.profileImage!)
                              : null,
                          child: student.profileImage == null
                              ? const Icon(Icons.person)
                              : null,
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Application Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                _buildStatusBadge(student.status),
                              ],
                            ),
                            if (student.status != 'pending') ...[
                              const SizedBox(height: 12),
                              if (student.reviewedAt != null)
                                Text(
                                  'Reviewed on: ${_formatTimestamp(student.reviewedAt)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              if (student.reviewNotes?.isNotEmpty ?? false) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Teacher\'s Notes:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    student.reviewNotes!,
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
      ),
    );
  }
}