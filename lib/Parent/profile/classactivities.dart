import 'package:flutter/material.dart';
import 'package:KinderConnect/Parent/profile/attendance_details.dart';
import 'class_activities_section.dart';
import 'package:flutter/services.dart'; 
import 'student_progress_section.dart';

class ParentActivitiesPage extends StatefulWidget {
  final String parentId;
  const ParentActivitiesPage({Key? key, required this.parentId}) : super(key: key);

  @override
  _ParentActivitiesPageState createState() => _ParentActivitiesPageState();
}

class _ParentActivitiesPageState extends State<ParentActivitiesPage> 
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late Animation<double> _titleAnimation;
  List<AnimationController> _tileControllers = [];
  List<Animation<double>> _tileAnimations = [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    
    // Title animation
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _titleAnimation = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeInOut,
    );
    _titleController.forward();

    // Tile animations
    for (int i = 0; i < 3; i++) {
      var controller = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _tileControllers.add(controller);
      
      _tileAnimations.add(Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      )));
      
      Future.delayed(Duration(milliseconds: 200 * i), () {
        controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _tileControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isRefreshing = false);
    
    // Replay tile animations
    for (int i = 0; i < _tileControllers.length; i++) {
      _tileControllers[i].reset();
      Future.delayed(Duration(milliseconds: 200 * i), () {
        _tileControllers[i].forward();
      });
    }
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required int index,
  }) {
    return FadeTransition(
      opacity: _tileAnimations[index],
      child: ScaleTransition(
        scale: _tileAnimations[index],
        child: Hero(
          tag: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                onTap();
              },
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 70, 150, 138).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 77, 147, 68),
                          Color.fromARGB(255, 100, 180, 90),
                        ],
                      ).createShader(bounds),
                      child: Icon(icon, size: 40),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
        //background image  
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/parentbgimage2.png'), // Add your image path here
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black12, // Slight dark overlay to ensure content visibility
                BlendMode.darken,
              ),
            ),
          ),
        ),

         RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 80.0, 20.0, 40.0),
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _titleAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.5),
                            end: Offset.zero,
                          ).animate(_titleAnimation),
                          child: _buildSectionTitle('Class Corner'),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildTileRow([
                        _buildDashboardTile(
                          icon: Icons.class_,
                          label: 'Class Activities',
                          onTap: () => _navigateToPage(ClassActivitiesSection(parentId: widget.parentId)),
                          index: 0,
                        ),
                        _buildDashboardTile(
                          icon: Icons.show_chart,
                          label: 'Student Progress',
                          onTap: () => _navigateToPage(
                            StudentProgressSection(parentId: widget.parentId),
                          ),
                          index: 1,
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildTileRow([
                        _buildDashboardTile(
                          icon: Icons.date_range,
                          label: 'Attendance Details',
                          onTap: () => _navigateToPage(
                            AttendanceDetails(parentId: widget.parentId),
                          ),
                          index: 2,
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(221, 3, 59, 34),
        ),
      ),
    );
  }

  Widget _buildTileRow(List<Widget> tiles) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: tiles,
    );
  }
}