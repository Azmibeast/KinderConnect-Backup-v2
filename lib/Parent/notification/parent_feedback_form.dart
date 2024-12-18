import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentFeedbackForm extends StatefulWidget {
  final String parentId;
  const ParentFeedbackForm({Key? key, required this.parentId}) : super(key: key);

  @override
  _ParentFeedbackFormState createState() => _ParentFeedbackFormState();
}

class _ParentFeedbackFormState extends State<ParentFeedbackForm> with SingleTickerProviderStateMixin {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  late TabController _tabController;
  String? _parentUsername;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchParentUsername();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feedbackController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchParentUsername() async {
    try {
      DocumentSnapshot parentDoc = await FirebaseFirestore.instance
          .collection('Parents')
          .doc(widget.parentId)
          .get();

      if (parentDoc.exists) {
        setState(() {
          _parentUsername = parentDoc['username'] ?? 'Anonymous';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to fetch user data');
    }
  }

  Future<void> _toggleLike(DocumentSnapshot feedbackDoc) async {
    try {
      final currentLiked = feedbackDoc['liked'] ?? false;
      final currentLikes = feedbackDoc['likes'] ?? 0;

      await FirebaseFirestore.instance
          .collection('feedbacks')
          .doc(feedbackDoc.id)
          .update({
        'liked': !currentLiked,
        'likes': currentLiked ? currentLikes - 1 : currentLikes + 1,
      });
    } catch (e) {
      _showErrorSnackBar('Failed to update like status');
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your feedback');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'name': _parentUsername ?? 'Anonymous',
        'feedback': _feedbackController.text.trim(),
        'liked': false,
        'likes': 0,
        'approved': false,
        'replied': false,
        'reply': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _feedbackController.clear();
      _showSuccessSnackBar('Feedback submitted for approval');
    } catch (e) {
      _showErrorSnackBar('Failed to submit feedback');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment(String feedbackId) async {
    if (_commentController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your comment');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('feedbacks')
          .doc(feedbackId)
          .collection('comments')
          .add({
        'comment': _commentController.text.trim(),
        'parentName': _parentUsername ?? 'Anonymous',
        'approved': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      _showSuccessSnackBar('Comment submitted for approval');
    } catch (e) {
      _showErrorSnackBar('Failed to submit comment');
    }
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFeedbackList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedbacks')
          .where('approved', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No approved feedback available',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const Divider(height: 32),
          itemBuilder: (context, index) {
            final feedbackDoc = snapshot.data!.docs[index];
            return _buildFeedbackCard(feedbackDoc);
          },
        );
      },
    );
  }

  Widget _buildFeedbackCard(DocumentSnapshot feedbackDoc) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (feedbackDoc['name'] as String).substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedbackDoc['name'] ?? 'Anonymous',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Posted ${_formatTimestamp(feedbackDoc['timestamp'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              feedbackDoc['feedback'] ?? 'No Feedback',
              style: const TextStyle(fontSize: 16),
            ),
            if (feedbackDoc['replied'] == true && feedbackDoc['reply'].isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Teacher\'s Reply:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(feedbackDoc['reply']),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        feedbackDoc['liked'] ? Icons.favorite : Icons.favorite_border,
                        color: feedbackDoc['liked'] ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleLike(feedbackDoc),
                    ),
                    Text('${feedbackDoc['likes']}'),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.comment),
                  label: const Text('Comment'),
                  onPressed: () => _showCommentDialog(feedbackDoc.id),
                ),
              ],
            ),
            _buildCommentSection(feedbackDoc.id),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection(String feedbackId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedbacks')
          .doc(feedbackId)
          .collection('comments')
          .where('approved', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Comments',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...snapshot.data!.docs.map((comment) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey.shade200,
                    child: Text(
                      (comment['parentName'] as String)
                          .substring(0, 1)
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment['parentName'] ?? 'Anonymous',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          comment['comment'] ?? 'No Comment',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        );
      },
    );
  }

  void _showCommentDialog(String feedbackId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Enter your comment',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _submitComment(feedbackId);
                Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Recently';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Feedback'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'View Feedback'),
            Tab(text: 'Submit Feedback'),
          ],
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFeedbackList(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Share Your Feedback',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _feedbackController,
                    decoration: const InputDecoration(
                      labelText: 'Your feedback',
                      hintText: 'What would you like to share?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Submit Feedback'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}