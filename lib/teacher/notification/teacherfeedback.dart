import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Feedback data model
class FeedbackItem {
  final String id;
  final String text;
  final String username;
  final bool approved;
  final bool liked;
  final int likes;
  final bool replied;
  final String reply;

  FeedbackItem({
    required this.id,
    required this.text,
    required this.username,
    required this.approved,
    required this.liked,
    required this.likes,
    required this.replied,
    required this.reply,
  });

  factory FeedbackItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackItem(
      id: doc.id,
      text: data['feedback'] ?? '',
      username: data['name'] ?? 'Anonymous',
      approved: data['approved'] ?? false,
      liked: data['liked'] ?? false,
      likes: data['likes'] ?? 0,
      replied: data['replied'] ?? false,
      reply: data['reply'] ?? '',
    );
  }
}

class TeacherFeedbackSection extends StatefulWidget {
  const TeacherFeedbackSection({super.key});

  @override
  State<TeacherFeedbackSection> createState() => _TeacherFeedbackSectionState();
}

class _TeacherFeedbackSectionState extends State<TeacherFeedbackSection> {
  final CollectionReference feedbackCollection =
      FirebaseFirestore.instance.collection('feedbacks');
  List<TextEditingController> _replyControllers = [];
  String _searchQuery = '';
  bool _showOnlyPending = false;

  @override
  void dispose() {
    for (var controller in _replyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Feedback Management Methods
  Future<void> _approveFeedback(String feedbackId) async {
    try {
      await feedbackCollection.doc(feedbackId).update({'approved': true});
      _showSuccessMessage('Feedback approved successfully');
    } catch (e) {
      _showErrorMessage('Error approving feedback: $e');
    }
  }

  Future<void> _replyToFeedback(String feedbackId, int index) async {
    try {
      String replyText = _replyControllers[index].text;
      if (replyText.isEmpty) {
        _showErrorMessage('Please enter a reply');
        return;
      }

      await feedbackCollection.doc(feedbackId).update({
        'replied': true,
        'reply': replyText,
      });
      
      setState(() {
        _replyControllers[index].clear();
      });
      
      _showSuccessMessage('Reply sent successfully');
    } catch (e) {
      _showErrorMessage('Error sending reply: $e');
    }
  }

  Future<void> _deleteFeedback(String feedbackId, int index) async {
    try {
      bool confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this feedback and all its comments?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (!confirmDelete) return;

      // Delete comments
      QuerySnapshot commentsSnapshot = await feedbackCollection
          .doc(feedbackId)
          .collection('comments')
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var comment in commentsSnapshot.docs) {
        batch.delete(comment.reference);
      }
      await batch.commit();

      // Delete feedback
      await feedbackCollection.doc(feedbackId).delete();

      setState(() {
        _replyControllers.removeAt(index);
      });

      _showSuccessMessage('Feedback and comments deleted successfully');
    } catch (e) {
      _showErrorMessage('Error deleting feedback: $e');
    }
  }

  Future<void> _deleteComment(String feedbackId, String commentId) async {
    try {
      bool confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Delete Comment'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (!confirmDelete) return;

      await feedbackCollection
          .doc(feedbackId)
          .collection('comments')
          .doc(commentId)
          .delete();
      
      _showSuccessMessage('Comment deleted successfully');
    } catch (e) {
      _showErrorMessage('Error deleting comment: $e');
    }
  }

  Future<void> _approveComment(String feedbackId, String commentId) async {
    try {
      await feedbackCollection
          .doc(feedbackId)
          .collection('comments')
          .doc(commentId)
          .update({'approved': true});
      _showSuccessMessage('Comment approved successfully');
    } catch (e) {
      _showErrorMessage('Error approving comment: $e');
    }
  }

  // UI Helper Methods
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // UI Components
  Widget _buildSearchBar() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search feedback...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            Switch(
              value: _showOnlyPending,
              onChanged: (value) {
                setState(() {
                  _showOnlyPending = value;
                });
              },
            ),
            const Text('Pending only'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackItem feedback, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 4,
      child: ExpansionTile(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(feedback.username[0].toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feedback.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    feedback.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 12,
              color: feedback.approved ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(feedback.approved ? 'Approved' : 'Pending'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedback.text,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        feedback.liked ? Icons.favorite : Icons.favorite_border,
                        color: feedback.liked ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        feedbackCollection.doc(feedback.id).update({
                          'liked': !feedback.liked,
                          'likes': feedback.liked ? feedback.likes - 1 : feedback.likes + 1,
                        });
                      },
                    ),
                    Text('${feedback.likes}'),
                    const Spacer(),
                    if (!feedback.approved)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Approve'),
                        onPressed: () => _approveFeedback(feedback.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteFeedback(feedback.id, index),
                    ),
                  ],
                ),
                const Divider(),
                if (feedback.replied)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Reply:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(feedback.reply),
                      ],
                    ),
                  )
                else
                  TextField(
                    controller: _replyControllers[index],
                    decoration: InputDecoration(
                      hintText: 'Type your reply...',
                      filled: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => _replyToFeedback(feedback.id, index),
                      ),
                    ),
                    maxLines: 3,
                  ),
                _buildCommentsSection(feedback.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(String feedbackId) {
    return StreamBuilder<QuerySnapshot>(
      stream: feedbackCollection
          .doc(feedbackId)
          .collection('comments')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data!.docs;
        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No comments yet'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Comments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                final commentData = comment.data() as Map<String, dynamic>;
                final bool isApproved = commentData['approved'] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: Text(
                        (commentData['parentName'] ?? 'A')[0].toUpperCase(),
                      ),
                    ),
                    title: Text(commentData['parentName'] ?? 'Anonymous'),
                    subtitle: Text(commentData['comment'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isApproved)
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () => _approveComment(feedbackId, comment.id),
                          )
                        else
                          const Icon(Icons.check_circle, color: Colors.green),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteComment(feedbackId, comment.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
        backgroundColor: Colors.blue[100],
        title: const Text('Teacher Feedback', style: TextStyle(fontWeight: FontWeight.w600),),
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchBar(),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: feedbackCollection.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No feedback available'),
                    );
                  }

                  var feedbackDocs = snapshot.data!.docs
                      .map((doc) => FeedbackItem.fromDocument(doc))
                      .where((feedback) {
                    final matchesSearch = feedback.text.toLowerCase().contains(_searchQuery) ||
                        feedback.username.toLowerCase().contains(_searchQuery);
                    final matchesPendingFilter = !_showOnlyPending || !feedback.approved;
                    return matchesSearch && matchesPendingFilter;
                  }).toList();

                  _replyControllers = List.generate(
                    feedbackDocs.length,
                    (index) => TextEditingController(),
                  );

                  if (feedbackDocs.isEmpty) {
                    return const Center(
                      child: Text('No matching feedback found'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: feedbackDocs.length,
                    itemBuilder: (context, index) =>
                        _buildFeedbackCard(feedbackDocs[index], index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}