import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:intl/intl.dart';

class ClassActivitiesSection extends StatefulWidget {
  final String parentId;
  const ClassActivitiesSection({Key? key, required this.parentId}) : super(key: key);
  @override
  _ClassActivitiesSectionState createState() => _ClassActivitiesSectionState();
}

class _ClassActivitiesSectionState extends State<ClassActivitiesSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, bool> isActivityExpanded = {};
  Map<String, bool> archivedActivities = {};

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

  Future<void> toggleArchive(String activityId, bool currentState) async {
    try {
      await FirebaseFirestore.instance
          .collection('class_activities')
          .doc(activityId)
          .update({'parentArchives.${widget.parentId}': !currentState});
      
      setState(() {
        archivedActivities[activityId] = !currentState;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentState ? 'Activity archived' : 'Activity unarchived'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update archive status'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildActivityCard(DocumentSnapshot activity, bool isPrevious) {
    final activityTitle = activity['title'] ?? 'No Title';
    final activityDescription = activity['activity'] ?? 'No description';
    final activityDate = (activity['date'] as Timestamp).toDate().add(const Duration(hours: 8));
    final formattedDate = DateFormat('dd-MM-yyyy').format(activityDate);
    final imageUrls = (activity.data() as Map<String, dynamic>).containsKey('imageUrls')
      ? List<String>.from(activity['imageUrls'] ?? [])
      : <String>[];
    final activityId = activity.id;
    final isExpanded = isActivityExpanded[activityId] ?? false;
    final parentArchives = activity['parentArchives'] ?? {};
    final isArchived = parentArchives[widget.parentId] ?? false;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isArchived ? Colors.grey[100] : Colors.white,
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                activityTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('$formattedDate\n$activityDescription'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(isArchived ? Icons.unarchive : Icons.archive),
                    onPressed: () => toggleArchive(activityId, isArchived),
                  ),
                  IconButton(
                    icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        isActivityExpanded[activityId] = !isExpanded;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (isExpanded && imageUrls.isNotEmpty)
              Container(
                height: 150,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageGalleryScreen(
                          images: imageUrls,
                          initialIndex: index,
                        ),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrls[index],
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 190, 237, 235),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Class Activities',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color.fromARGB(255, 70, 150, 138).withOpacity(0.9),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: "Previous"),
            Tab(icon: Icon(Icons.upcoming), text: "Upcoming"),
            Tab(icon: Icon(Icons.archive), text: "Archived"),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildActivityList(isPrevious: true, showArchived: false),
              _buildActivityList(isPrevious: false, showArchived: false),
              _buildActivityList(showArchived: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList({bool? isPrevious, required bool showArchived}) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('class_activities')
          .orderBy('date', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var activities = snapshot.data!.docs.where((activity) {
          final parentArchives = activity['parentArchives'] ?? {};
  final isArchivedForParent = parentArchives[widget.parentId] ?? false;

  if (showArchived) return isArchivedForParent;

  if (!showArchived && isArchivedForParent) return false;

  if (isPrevious != null) {
    final activityDate = (activity['date'] as Timestamp)
        .toDate()
        .add(const Duration(hours: 8));
    return isPrevious
        ? activityDate.isBefore(todayEnd)
        : activityDate.isAfter(todayEnd);
  }
  return true;
}).toList();

        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 30, color: Colors.red,),
                const SizedBox(height: 15,),
                Text(
                showArchived
                    ? 'No archived activities'
                    : isPrevious!
                        ? 'No previous activities'
                        : 'No upcoming activities',
                style: const TextStyle(fontSize: 16),
              ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) =>
              _buildActivityCard(activities[index], isPrevious ?? false),
        );
      },
    );
  }
}

class ImageGalleryScreen extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const ImageGalleryScreen({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Images'),
        backgroundColor: const Color.fromARGB(255, 140, 93, 151),
      ),
      body: PhotoViewGallery.builder(
        itemCount: images.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(images[index]),
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        pageController: PageController(initialPage: initialIndex),
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}