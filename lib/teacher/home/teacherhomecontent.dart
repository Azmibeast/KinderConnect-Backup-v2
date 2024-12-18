import 'package:KinderConnect/teacher/home/editattendance.dart';
import 'package:KinderConnect/teacher/home/editspecialevent.dart';
import 'package:KinderConnect/teacher/home/updateclassactivities.dart';
import 'package:KinderConnect/teacher/notification/teacherriminder.dart';
import 'package:KinderConnect/teacher/profile/teacherclassactivities.dart';
import 'package:KinderConnect/welcome.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherHomePage extends StatefulWidget {
  final String teacherId;

  const TeacherHomePage({Key? key, required this.teacherId}) : super(key: key);
  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  List<Widget> _getPages() {
    return [
      const TeacherActivitiesPage(),
      TeacherHomeContent(teacherId: widget.teacherId),
      const TeacherReminderPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    print("Teacher ID: ${widget.teacherId}");

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _getPages()[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          animationDuration: const Duration(milliseconds: 400),
          destinations: [
            _buildNavDestination(Icons.person_outlined, Icons.person, 'Profile'),
            _buildNavDestination(Icons.home_outlined, Icons.home, 'Home'),
            _buildNavDestination(Icons.notifications_outlined, Icons.notifications, 'Notification'),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination(IconData outlinedIcon, IconData filledIcon, String label) {
    return NavigationDestination(
      icon: Icon(outlinedIcon, color: Colors.grey),
      selectedIcon: Icon(filledIcon, color: Colors.green),
      label: label,
    );
  }
}

class TeacherHomeContent extends StatefulWidget {
  final String teacherId;
  const TeacherHomeContent({Key? key, required this.teacherId}) : super(key: key);

  @override
  _TeacherHomeContentState createState() => _TeacherHomeContentState();
}

class _TeacherHomeContentState extends State<TeacherHomeContent> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<AnimationController> _animationControllers = [];
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  String? _username; // State to hold the teacher's username

  Future<void> _fetchUsername() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Teachers')
          .doc(widget.teacherId)
          .get();
      if (doc.exists) {
        if (mounted) {
        setState(() {
          _username = doc.data()?['username'] ?? 'Unknown';
        });
        }
      } else {
        if (mounted) {
        setState(() {
          _username = 'Unknown';
        });
        }
      }
    } catch (e) {
      if (mounted) {
      setState(() {
        _username = 'Error fetching name';
      });
    }
    }
  }

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _animationControllers.add(AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ));
    }
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _backgroundAnimation = Tween<double>(begin: 0, end: 1).animate(_backgroundController);

    _fetchUsername();

    // Stagger the entrance animations
    Future.delayed(const Duration(milliseconds: 100), () {
      for (var i = 0; i < _animationControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 100), () {
          _animationControllers[i].forward();
        });
      }
    });

  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _backgroundController.dispose();
    super.dispose();
  }

  void _navigateToPage(int pageIndex, Widget page) {
    setState(() {
      _currentPage = pageIndex;
    });
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    ).then((_) {
    setState(() {
      for (var controller in _animationControllers) {
        controller.forward(); // Restart the animation
      }
    });
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.brown[100]!,
                      Colors.green[100]!,
                    ],
                    transform: GradientRotation(_backgroundAnimation.value * 2 * 3.14159),
                  ),
                ),
              );
            },
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Attendance'),
                  _buildTileRow([
                    _buildDashboardTile(
                      icon: Icons.edit_document,
                      label: 'Attendance',
                      onTap: () => _navigateToPage(0, const EditAttendance()),
                      animationController: _animationControllers[0],
                    ),
                  ]),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Class Activities & Special Events'),
                  _buildTileRow([
                    _buildDashboardTile(
                      icon: Icons.edit_outlined,
                      label: 'Class\nActivity',
                      onTap: () => _navigateToPage(1, ClassActivitiesSection(teacherId: widget.teacherId)),
                      animationController: _animationControllers[1],
                    ),
                    _buildDashboardTile(
                      icon: Icons.edit_calendar_outlined,
                      label: 'Special\nEvent',
                      onTap: () => _navigateToPage(2, const EditSpecialEvent()),
                      animationController: _animationControllers[2],
                    ),
                  ]),
                ],
              ),
            ),
          ),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.green,
            child: Icon(Icons.school, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _username ?? 'Loading...',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          shadows: [
            Shadow(
              offset: Offset(0, 1),
              blurRadius: 2,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTileRow(List<Widget> tiles) {
    return Row(
      mainAxisAlignment: tiles.length == 1 
          ? MainAxisAlignment.start 
          : MainAxisAlignment.spaceAround,
      children: tiles,
    );
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AnimationController animationController,
  }) {
    Animation<double> scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutBack,
      ),
    );

    Animation<double> hoverAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );

    return ScaleTransition(
      scale: scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => animationController.forward(),
        onTapUp: (_) {
          animationController.reverse();
          onTap();
        },
        onTapCancel: () => animationController.reverse(),
        child: AnimatedBuilder(
          animation: hoverAnimation,
          builder: (context, child) => Transform.scale(
            scale: hoverAnimation.value,
            child: Container(
              width: 140,
              height: 140,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 35,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Positioned(
      top: 90,
      right: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const Welcome()),
                          (Route<dynamic> route) => false,
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.logout, color: Colors.red, size: 24),
          ),
        ),
      ),
    );
  }
}