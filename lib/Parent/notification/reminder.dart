import 'package:KinderConnect/Parent/notification/childapplicationstatus.dart';
import 'package:flutter/material.dart';
import 'parent_feedback_form.dart';
import 'event_reminder_form.dart';

class Reminder extends StatefulWidget {
  final String parentId;
  const Reminder({Key? key, required this.parentId}) : super(key: key);

  @override
  _ReminderState createState() => _ReminderState();
}

class _ReminderState extends State<Reminder> with TickerProviderStateMixin {
  List<AnimationController> _animationControllers = [];
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  late AnimationController _titleAnimationController;
  late Animation<double> _titleAnimation;
  
  final List<Map<String, dynamic>> _tiles = [
    {
      'icon': Icons.feedback_outlined,
      'label': 'Feedback',
      'gradientColors': [const Color(0xFF66BB6A), const Color(0xFF43A047)],
    },
    {
      'icon': Icons.event_note_outlined,
      'label': 'Event Reminders',
      'gradientColors': [const Color(0xFF64B5F6), const Color(0xFF1E88E5)],
    },
    {
      'icon': Icons.notification_important,
      'label': 'Child Status',
      'gradientColors': [const Color.fromARGB(255, 246, 188, 100), const Color.fromARGB(255, 246, 188, 100),],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Tile animations
    for (int i = 0; i < _tiles.length; i++) {
      _animationControllers.add(
        AnimationController(
          duration: const Duration(milliseconds: 200),
          vsync: this,
        ),
      );
    }

    // Background animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(begin: 0, end: 1).animate(_backgroundController);

    // Title bounce animation
    _titleAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _titleAnimation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _titleAnimationController, curve: Curves.bounceOut),
    );

    // Start the title animation
    _titleAnimationController.forward();
  
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _backgroundController.dispose();
    super.dispose();
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(0.0, 0.1);
          var end = Offset.zero;
          var curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          
          var fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          ));
          
          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/parentbgimage3.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.1 + (_backgroundAnimation.value * 0.1)),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _titleAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _titleAnimation.value),
                            child: _buildHeader(),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      _buildTilesGrid(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Reminders',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.green[800],
        letterSpacing: 1.2,
      ),
      
    );
  }

  Widget _buildTilesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1,
      ),
      itemCount: _tiles.length,
      itemBuilder: (context, index) {
        // Create fade-in-up animation
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 800 + (index * 200)),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 1.0, end: 0.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * value),
              child: Opacity(
                opacity: 1 - value,
                child: child,
              ),
            );
          },
          child: _buildDashboardTile(
            icon: _tiles[index]['icon'],
            label: _tiles[index]['label'],
            gradientColors: _tiles[index]['gradientColors'],
            onTap: () => _navigateToPage(
              index == 0
                  ? ParentFeedbackForm(parentId: widget.parentId)
                  : index == 1
                      ? EventReminderForm()
                      : ParentStudentStatusPage(parentId: widget.parentId),
                    
            ),
            animationController: _animationControllers[index],
          ),
        );
      },
    );
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required AnimationController animationController,
  }) {
    Animation<double> scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    return GestureDetector(
      onTapDown: (_) => animationController.forward(),
      onTapUp: (_) {
        animationController.reverse();
        onTap();
      },
      onTapCancel: () => animationController.reverse(),
      child: ScaleTransition(
        scale: scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}