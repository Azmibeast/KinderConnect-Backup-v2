import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class StudentProgressSection extends StatefulWidget {
  final String parentId;

  const StudentProgressSection({Key? key, required this.parentId}) : super(key: key);

  @override
  _StudentProgressSectionState createState() => _StudentProgressSectionState();
}

class _StudentProgressSectionState extends State<StudentProgressSection> with SingleTickerProviderStateMixin {
  String? selectedChildId;
  String? selectedChildName;
  String? profileImageUrl;
  String? selectedExam;
  int? touchedIndex;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Enhanced grade styling
  final Map<String, double> gradeToHeight = {
    'A': 5.0,
    'B': 4.0,
    'C': 3.0,
    'D': 2.0,
    'E': 1.0,
  };

   final Map<String, Color> gradeColors = {
    'A': Colors.green,
    'B': Colors.blue,
    'C': Colors.yellow,
    'D': Colors.orange,
    'E': Colors.red,
  };

  final Map<String, GradeStyle> gradeStyles = {
    'A': GradeStyle(
      color: Colors.green.shade400,
      icon: Icons.star,
      label: 'Excellent'
    ),
    'B': GradeStyle(
      color: Colors.blue.shade400,
      icon: Icons.thumb_up,
      label: 'Good'
    ),
    'C': GradeStyle(
      color: Colors.amber.shade400,
      icon: Icons.trending_flat,
      label: 'Average'
    ),
    'D': GradeStyle(
      color: Colors.orange.shade400,
      icon: Icons.warning,
      label: 'Need Improvement'
    ),
    'E': GradeStyle(
      color: Colors.red.shade400,
      icon: Icons.warning_amber,
      label: 'Critical'
    ),
  };

  final List<String> monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to get month index
  int getMonthIndex(String month) {
    return monthNames.indexWhere(
      (name) => name.toLowerCase().startsWith(month.toLowerCase()),
    );
  }

  Widget _buildChildSelector(List<QueryDocumentSnapshot> children) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        itemBuilder: (context, index) {
          var child = children[index];
          bool isSelected = child.id == selectedChildId;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedChildId = child.id;
                selectedChildName = child['name'];
                profileImageUrl = child['profile_image'];
                selectedExam = null;
                touchedIndex = null;
              });
              _animationController.reset();
              _animationController.forward();
            },
            child: FadeInLeft(
              delay: Duration(milliseconds: 100 * index),
              child: Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color.fromARGB(255, 70, 150, 138).withOpacity(0.9) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'profile_${child.id}',
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: child['profile_image'] != null
                            ? NetworkImage(child['profile_image'])
                            : const AssetImage('assets/images/student_profile.jpg') as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      child['name'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExamSelector(List<String> exams) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: exams.length,
        itemBuilder: (context, index) {
          var exam = exams[index];
          bool isSelected = exam == selectedExam;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FadeInRight(
              delay: Duration(milliseconds: 100 * index),
              child: FilterChip(
                label: Text(exam),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    selectedExam = selected ? exam : null;
                    touchedIndex = null;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
                selectedColor: const Color.fromARGB(255, 70, 150, 138).withOpacity(0.9),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradeLegend() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: gradeStyles.entries.map((entry) {
        return FadeInUp(
          child: Tooltip(
            message: entry.value.label,
            child: Chip(
              avatar: Icon(
                entry.value.icon,
                color: entry.value.color,
                size: 18,
              ),
              label: Text(
                'Grade ${entry.key}',
                style: TextStyle(
                  color: entry.value.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: entry.value.color.withOpacity(0.1),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F2F1),
              Color(0xFFB2DFDB),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 100.0,
                floating: true,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Student Progress',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFE0F2F1),
                          const Color(0xFFE0F2F1).withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('students')
                            .where('parent_id', isEqualTo: widget.parentId)
                            .where('isApproved', isEqualTo: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                           return Center(
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
                          );
                          }
                          // Data is available
                          return _buildChildSelector(snapshot.data!.docs);
                        },
                      ),
                      if (selectedChildId != null) ...[
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Exam Selection',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('students')
                                        .doc(selectedChildId)
                                        .collection('progress')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      var exams = snapshot.data!.docs
                                          .map((doc) => doc['exam'].toString())
                                          .toSet()
                                          .toList();
                                      return _buildExamSelector(exams);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Grade Performance',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildGradeLegend(),
                                  if (selectedExam != null) ...[
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      height: 300,
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('students')
                                            .doc(selectedChildId)
                                            .collection('progress')
                                            .where('exam', isEqualTo: selectedExam)
                                            .orderBy('month')
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No progress data available.',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                );
                              }
        
                              // Create a sorted list of documents based on month
                              var sortedDocs = snapshot.data!.docs.toList()
                                ..sort((a, b) {
                                  int monthA = getMonthIndex(a['month']);
                                  int monthB = getMonthIndex(b['month']);
                                  return monthA.compareTo(monthB);
                                });
        
                              List<BarChartGroupData> barGroups = [];
                              Map<int, String> monthMapping = {};
        
                              for (int i = 0; i < sortedDocs.length; i++) {
                                var doc = sortedDocs[i];
                                String month = doc['month'];
                                String grade = doc['grade'];
                                double? height = gradeToHeight[grade];
                                
                                if (height != null) {
                                  monthMapping[i] = month;
                                  barGroups.add(
                                    BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: height,
                                          color: gradeColors[grade],
                                          width: 15,
                                          backDrawRodData: BackgroundBarChartRodData(
                                            show: true,
                                            toY: 5,
                                            color: Colors.transparent,
                                          ),
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(6),
                                          ),
                                        ),
                                      ],
                                      showingTooltipIndicators: touchedIndex == i ? [0] : [],
                                    ),
                                  );
                                }
                              }
        
                              return BarChart(
                                BarChartData(
                                  barGroups: barGroups,
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          String grade = gradeToHeight.keys
                                              .firstWhere((k) => gradeToHeight[k] == value,
                                                  orElse: () => '');
                                          return Text(grade);
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          String month = monthMapping[value.toInt()] ?? '';
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              month,
                                              style: TextStyle(
                                                fontSize: touchedIndex == value.toInt() ? 12 : 10,
                                                fontWeight: touchedIndex == value.toInt()
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  gridData: const FlGridData(show: true),
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      //tooltipBgColor: Colors.blueGrey,
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        String grade = gradeToHeight.keys.firstWhere(
                                            (k) => gradeToHeight[k] == rod.toY,
                                            orElse: () => '');
                                        String month = monthMapping[group.x] ?? '';
                                        return BarTooltipItem(
                                          'Grade: $grade\n$month',
                                          const TextStyle(color: Colors.white),
                                        );
                                      },
                                    ),
                                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                                      setState(() {
                                        if (event is! FlTapUpEvent ||
                                            barTouchResponse == null ||
                                            barTouchResponse.spot == null) {
                                          touchedIndex = null;
                                          return;
                                        }
                                        touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GradeStyle {
  final Color color;
  final IconData icon;
  final String label;

  GradeStyle({
    required this.color,
    required this.icon,
    required this.label,
  });
}