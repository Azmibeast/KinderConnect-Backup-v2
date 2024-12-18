import 'package:KinderConnect/teacher/notification/attendancenotification.dart';
import 'package:KinderConnect/teacher/notification/newstudentnotification.dart';
import 'package:KinderConnect/teacher/notification/teacherfeedback.dart';
import 'package:flutter/material.dart';

class TeacherReminderPage extends StatefulWidget {
  const TeacherReminderPage({super.key});

  @override
  State<TeacherReminderPage> createState() => _TeacherReminderPageState();
}

class _TeacherReminderPageState extends State<TeacherReminderPage> 
    with TickerProviderStateMixin {
  // List to hold the controllers for each dashboard tile
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;
  late AnimationController _pageEnterController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize page enter animation
    _pageEnterController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageEnterController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageEnterController,
      curve: Curves.easeOutCubic,
    ));

    // Initialize tile animations
    _animationControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    _rotationAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0, end: 0.05).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Start page enter animation
    _pageEnterController.forward();
  }

  @override
  void dispose() {
    _pageEnterController.dispose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var curve = Curves.easeInOut;
          var curveTween = CurveTween(curve: curve);
          
          return FadeTransition(
            opacity: animation.drive(curveTween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[100],
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/teacherbg2.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black12,
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          
          // Content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 80.0, 20.0, 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildSectionTitle('Reminders'),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDashboardTile(
                          icon: Icons.feedback_outlined,
                          label: 'Feedback Notifications',
                          onTap: () => _navigateToPage(const TeacherFeedbackSection()),
                          index: 0,
                          color: Colors.blue[100]!,
                        ),
                        _buildDashboardTile(
                          icon: Icons.notifications_active_outlined,
                          label: 'Absent Notifications',
                          onTap: () => _navigateToPage(const AbsentNotification()),
                          index: 1,
                          color: Colors.green[100]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: _buildDashboardTile(
                        icon: Icons.person_add_alt_outlined,
                        label: 'New Student Application',
                        onTap: () => _navigateToPage(const NewStudentNotification()),
                        index: 2,
                        color: Colors.orange[100]!,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required int index,
    required Color color,
  }) {
    return GestureDetector(
      onTapDown: (_) => _animationControllers[index].forward(),
      onTapUp: (_) {
        _animationControllers[index].reverse();
        onTap();
      },
      onTapCancel: () => _animationControllers[index].reverse(),
      child: AnimatedBuilder(
        animation: _animationControllers[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimations[index].value,
            child: Transform.rotate(
              angle: _rotationAnimations[index].value,
              child: Container(
                width: 160,
                height: 160,
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.2,
                      ),
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
}