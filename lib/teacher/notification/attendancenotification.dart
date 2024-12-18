import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AbsentNotification extends StatefulWidget {
  const AbsentNotification({super.key});

  @override
  State<AbsentNotification> createState() => _AbsentNotificationState();
}

class _AbsentNotificationState extends State<AbsentNotification> {
  List<String> deletedAbsences = [];
  
  // Firebase Operations
  Future<void> validateAbsence(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('absent_notice')
          .doc(docId)
          .update({'isValidated': true});
      _showSnackBar(
        'Absence validated successfully',
        icon: Icons.check_circle,
        color: Colors.green,
      );
    } catch (e) {
      _showSnackBar(
        'Failed to validate absence',
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  Future<void> deleteAbsence(String docId) async {
    try {
      _showSnackBar(
        'Deleting notice...',
        duration: const Duration(seconds: 1),
      );

      await FirebaseFirestore.instance
          .collection('absent_notice')
          .doc(docId)
          .delete();

      setState(() => deletedAbsences.add(docId));

      _showSnackBar(
        'Absence notice deleted',
        icon: Icons.delete,
        color: Colors.red,
      );
    } catch (e) {
      _showSnackBar(
        'Failed to delete absence',
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  Future<String> getStudentName(String childId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(childId)
          .get();
      return snapshot['name'] ?? 'Unknown Name';
    } catch (e) {
      debugPrint('Error fetching student name: $e');
      return 'Unknown Name';
    }
  }

  // UI Helpers
  void _showSnackBar(
    String message, {
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(message),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('dd-MM-yyyy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[100],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text('Absent Students', style: TextStyle(fontWeight: FontWeight.w600),),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildAbsencesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Absent Students Notification',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Track and manage student absences',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsencesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('absent_notice')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) => _buildAbsenceCard(snapshot.data!.docs[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No absences reported',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceCard(DocumentSnapshot document) {
    final studentData = document.data() as Map<String, dynamic>;
    final childId = studentData['childId'];
    final isDeleted = deletedAbsences.contains(document.id);

    return AnimatedOpacity(
      opacity: isDeleted ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 500),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: studentData['isValidated'] ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: FutureBuilder<String>(
          future: getStudentName(childId),
          builder: (context, nameSnapshot) {
            if (!nameSnapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return ExpansionTile(
              title: Text(
                nameSnapshot.data!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_formatDate(studentData['date'])),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Reason', studentData['attendanceStatus']),
                      const SizedBox(height: 8),
                      _buildAttachmentButton(studentData['attachment']),
                      const SizedBox(height: 16),
                      _buildActionButtons(document.id, studentData['isValidated']),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildAttachmentButton(String attachment) {
    return TextButton.icon(
      onPressed: () {
        _showSnackBar('Opening $attachment');
      },
      icon: const Icon(Icons.attach_file),
      label: Text(
        attachment,
        style: const TextStyle(decoration: TextDecoration.underline),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _buildActionButtons(String docId, bool isValidated) {
    if (isValidated) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          const Text(
            'Validated',
            style: TextStyle(color: Colors.green),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.red,
            onPressed: () => deleteAbsence(docId),
            tooltip: 'Delete absence',
          ),
        ],
      );
    }

    return ElevatedButton(
      onPressed: () => validateAbsence(docId),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, color: Colors.white,),
          SizedBox(width: 8),
          Text('Validate', style: TextStyle(color: Colors.white),),
        ],
      ),
    );
  }
}