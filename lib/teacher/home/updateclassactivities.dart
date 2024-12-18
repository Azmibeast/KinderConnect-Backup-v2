import 'package:KinderConnect/teacher/home/classactivitiesplan.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ClassActivitiesSection extends StatefulWidget {
  final String teacherId;

  const ClassActivitiesSection({Key? key, required this.teacherId}) : super(key: key);
  @override
  _ClassActivitiesSectionState createState() => _ClassActivitiesSectionState();
}

class _ClassActivitiesSectionState extends State<ClassActivitiesSection> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteActivity(String activityId) async {
  setState(() => _isLoading = true);

  // Fetch the activity document
  final activity = await FirebaseFirestore.instance
      .collection('class_activities')
      .doc(activityId)
      .get();

  // Check if the activity exists and the teacherId matches
  if (activity.exists && activity['teacherId'] == widget.teacherId) {
    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    // Perform deletion if confirmed
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('class_activities')
          .doc(activityId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity deleted successfully')),
      );
    }
  } else {
    // Show error if the teacher doesn't have permission
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You do not have permission to delete this activity')),
    );
  }

  setState(() => _isLoading = false);
}


  Future<void> _archiveActivity(String activityId) async {
    setState(() => _isLoading = true);

  final activity = await FirebaseFirestore.instance
      .collection('class_activities')
      .doc(activityId)
      .get();

  if (activity.exists && activity['teacherId'] == widget.teacherId) {
    await FirebaseFirestore.instance
        .collection('class_activities')
        .doc(activityId)
        .update({'isArchived': true});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity archived successfully')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You do not have permission to archive this activity')),
    );
  }

  setState(() => _isLoading = false);
}

  Future<void> _unarchiveActivity(String activityId) async {
    setState(() => _isLoading = true);

  final activity = await FirebaseFirestore.instance
      .collection('class_activities')
      .doc(activityId)
      .get();

  if (activity.exists && activity['teacherId'] == widget.teacherId) {
    await FirebaseFirestore.instance
        .collection('class_activities')
        .doc(activityId)
        .update({'isArchived': false});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity unarchived successfully')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You do not have permission to unarchive this activity')),
    );
  }

  setState(() => _isLoading = false);
}

  Future<void> _uploadImages(String activityId) async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() => _isLoading = true);
        List<String> imageUrls = [];

        for (var pickedFile in pickedFiles) {
          final File file = File(pickedFile.path);
          final ref = FirebaseStorage.instance
              .ref()
              .child('class_activities')
              .child(activityId)
              .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

          await ref.putFile(file);
          final imageUrl = await ref.getDownloadURL();
          imageUrls.add(imageUrl);
        }

        await FirebaseFirestore.instance
            .collection('class_activities')
            .doc(activityId)
            .update({
          'imageUrls': FieldValue.arrayUnion(imageUrls),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Images uploaded successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload images')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildActivityCard(DocumentSnapshot activity, bool isPrevious) {
    final activityTitle = activity['title'] ?? 'Untitled Activity';
    final activityId = activity.id;
    final activityDate = (activity['date'] as Timestamp)
        .toDate()
        .add(const Duration(hours: 8));
    final formattedDate = DateFormat('dd-MM-yyyy').format(activityDate);
    final imageUrls = (activity.data() as Map<String, dynamic>)
            .containsKey('imageUrls')
        ? List<String>.from(activity['imageUrls'])
        : [];
    final isArchived = activity['isArchived'] ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            activityTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            formattedDate,
            style: TextStyle(color: Colors.grey[600]),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrls.isNotEmpty)
                    Container(
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () => _showImagePreview(context, imageUrls[index]),
                              child: Hero(
                                tag: imageUrls[index],
                                child: Container(
                                  width: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 1,
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrls[index],
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Text(
                            'No pictures available',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isPrevious && !isArchived)
                        IconButton(
                          icon: const Icon(Icons.archive),
                          color: Colors.blue,
                          onPressed: () => _archiveActivity(activityId),
                          tooltip: 'Archive Activity',
                        ),
                      if (isArchived)
                        IconButton(
                          icon: const Icon(Icons.unarchive),
                          color: Colors.green,
                          onPressed: () => _unarchiveActivity(activityId),
                          tooltip: 'Unarchive Activity',
                        ),
                      IconButton(
                        icon: const Icon(Icons.add_photo_alternate),
                        color: Colors.green,
                        onPressed: () => _uploadImages(activityId),
                        tooltip: 'Add Photos',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () => _deleteActivity(activityId),
                        tooltip: 'Delete Activity',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
   Widget build(BuildContext context) {
    
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day + 1);
    final malaysiaTimeOffset = const Duration(hours: 8);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Class Activities',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Previous'),
            Tab(text: 'Archived'),
          ],
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
        child: SafeArea(
          child: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  // Upcoming Activities Tab
                  _buildActivitiesTab(
                    stream: FirebaseFirestore.instance
                        .collection('class_activities')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    filterFn: (activity) {
                      final activityDate = (activity['date'] as Timestamp)
                          .toDate()
                          .add(malaysiaTimeOffset);
                      final isArchived = activity['isArchived'] ?? false;
                      return !isArchived && activityDate.isAfter(todayEnd);
                    },
                    emptyMessage: 'No upcoming activities',
                    isPrevious: false,
                  ),
        
                  // Previous Activities Tab
                  _buildActivitiesTab(
                    stream: FirebaseFirestore.instance
                        .collection('class_activities')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    filterFn: (activity) {
                      final activityDate = (activity['date'] as Timestamp)
                          .toDate()
                          .add(malaysiaTimeOffset);
                      final isArchived = activity['isArchived'] ?? false;
                      return !isArchived && activityDate.isBefore(todayEnd);
                    },
                    emptyMessage: 'No previous activities',
                    isPrevious: true,
                  ),
        
                  // Archived Activities Tab
                  _buildActivitiesTab(
                    stream: FirebaseFirestore.instance
                        .collection('class_activities')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    filterFn: (activity) => activity['isArchived'] == true,
                    emptyMessage: 'No archived activities',
                    isPrevious: true,
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlanClassActivitiesForm(teacherId: widget.teacherId),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white,),
        label: const Text('New Activity', style: TextStyle(color: Colors.white),),
        backgroundColor: const Color.fromARGB(255, 7, 116, 11),
      ),
    );
  }

  Widget _buildActivitiesTab({
    required Stream<QuerySnapshot> stream,
    required bool Function(DocumentSnapshot) filterFn,
    required String emptyMessage,
    required bool isPrevious,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data?.docs.where(filterFn).toList() ?? [];

        if (activities.isEmpty) {
          return BounceInDown(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildActivityCard(activities[index], isPrevious),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              PhotoView(
                imageProvider: NetworkImage(imageUrl),
                backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
