import 'package:KinderConnect/teacher/profile/editstudentdetails.dart';
import 'package:KinderConnect/teacher/profile/updateprogress.dart';
import 'package:flutter/material.dart';

class TeacherActivitiesPage extends StatefulWidget {
  const TeacherActivitiesPage({super.key});

  @override
  State<TeacherActivitiesPage> createState() => _TeacherActivitiesPageState();
}

class _TeacherActivitiesPageState extends State<TeacherActivitiesPage> 
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _pageLoadController;
  List<AnimationController> _tileControllers = [];
  bool _isLoading = true;

  // Add hover states for tiles
  List<bool> _isHovered = [false, false];

  @override
  void initState() {
    super.initState();
    // Initialize page load animation
    _pageLoadController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    // Initialize tile animations
    for (int i = 0; i < 2; i++) {
      _tileControllers.add(AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ));
    }

    // Simulate loading state
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageLoadController.dispose();
    for (var controller in _tileControllers) {
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
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AnimationController animationController,
    required int index,
  }) {
    // Create multiple animations
    Animation<double> scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );

    Animation<double> slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _pageLoadController,
        curve: Interval(index * 0.2, 0.6 + index * 0.2, curve: Curves.easeOutCubic),
      ),
    );

    return AnimatedBuilder(
      animation: _pageLoadController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, slideAnimation.value),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _isLoading ? 0.0 : 1.0,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered[index] = true),
              onExit: (_) => setState(() => _isHovered[index] = false),
              child: GestureDetector(
                onTapDown: (_) => animationController.forward(),
                onTapUp: (_) {
                  animationController.reverse();
                  onTap();
                },
                onTapCancel: () => animationController.reverse(),
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: _isHovered[index]
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(_isHovered[index] ? 0.8 : 0.5),
                          spreadRadius: _isHovered[index] ? 7 : 5,
                          blurRadius: _isHovered[index] ? 10 : 7,
                          offset: Offset(0, _isHovered[index] ? 5 : 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          transform: Matrix4.identity()
                            ..scale(_isHovered[index] ? 1.1 : 1.0),
                          child: Icon(
                            icon,
                            size: 45,
                            color: const Color.fromARGB(255, 77, 147, 68),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[100],
      body: Stack(
        children: [
          // Background with parallax effect
          AnimatedBuilder(
            animation: _pageLoadController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/teacherbg1.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.15),
                      BlendMode.darken,
                    ),
                    alignment: Alignment(
                      0.0,
                      0.2 - (_pageLoadController.value * 0.1),
                    ),
                  ),
                ),
              );
            },
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated title
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-0.2, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _pageLoadController,
                      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                    )),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _pageLoadController,
                          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                        ),
                      ),
                      child: _buildSectionTitle('Students Data'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tiles
                  _buildTileRow([
                    _buildDashboardTile(
                      icon: Icons.trending_up,
                      label: 'Student Progress',
                      onTap: () => _navigateToPage(const UpdateStudentProgress()),
                      animationController: _tileControllers[0],
                      index: 0,
                    ),
                    _buildDashboardTile(
                      icon: Icons.person_outline,
                      label: 'Student Details',
                      onTap: () => _navigateToPage(const EditStudentDetailsSection()),
                      animationController: _tileControllers[1],
                      index: 1,
                    ),
                  ]),
                ],
              ),
            ),
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
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(221, 10, 10, 10),
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              offset: Offset(2.0, 2.0),
              blurRadius: 4.0,
              color: Color.fromARGB(100, 0, 0, 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTileRow(List<Widget> tiles) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tiles.map((tile) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: tile,
        ),
      )).toList(),
    );
  }
}