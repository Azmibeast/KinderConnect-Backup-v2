import 'package:KinderConnect/Parent/home/registernewstudent.dart';
import 'package:KinderConnect/Parent/notification/reminder.dart';
import 'package:KinderConnect/Parent/profile/classactivities.dart';
import 'package:KinderConnect/welcome.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'attendance_form.dart';
import 'updatedetails.dart';
import 'dart:async';


class HomePage extends StatefulWidget {
  final String parentId;

  const HomePage({Key? key, required this.parentId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  late List<Widget> _pages;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pages = [
      ParentActivitiesPage(parentId: widget.parentId),
      HomeContent(parentId: widget.parentId),
      Reminder(parentId: widget.parentId),
    ];

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color.fromARGB(255, 173, 175, 175),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        animationDuration: const Duration(milliseconds: 400),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notification',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final String parentId;

  const HomeContent({Key? key, required this.parentId}) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = false;
  int _currentImageIndex = 0;
  Timer? _imageTimer;
  String? _username;

  final List<String> _motivationalQuotes = [
    "Every child is a different kind of flower, and all together, they make this world a beautiful garden.",
    "Believe in your child's potential, and watch them bloom.",
    "Nurturing a child's dreams is the most important job in the world.",
    "Your support today shapes their tomorrow.",
    "Education is not the filling of a pail, but the lighting of a fire."
  ];

   // Add image assets list
  final List<String> _imageAssets = [
    'assets/images/kids1.jpg',
    'assets/images/kids2.jpg',
    'assets/images/kids3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _controller.forward();
    _startImageTimer();
    _fetchParentUsername();
  }

  void _startImageTimer() {
    _imageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _imageAssets.length;
      });
    });
  }

  Future<void> _fetchParentUsername() async {
    try {
      setState(() => _isLoading = true);
      final doc = await FirebaseFirestore.instance.collection('Parents').doc(widget.parentId).get();
      if (doc.exists) {
        setState(() {
          _username = doc['username']; // Assuming the field name is 'username'
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _imageTimer?.cancel();
    super.dispose();
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Welcome()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 219, 143, 240), Color(0xFFFFF3E0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 100.0, 20.0, 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the username
                if (_username != null)
                  Row(
                    children: [
                      const Text(
                      'Welcome,',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      ' $_username!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(221, 1, 142, 30),
                      ),
                    ),
                    ],
                  ),
                  
                const SizedBox(height: 10),
                _buildCustomHeader(context),
                const SizedBox(height: 25),
                _buildSectionTitle('Child Management'),
                //const SizedBox(height: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 30,
                          mainAxisSpacing: 20,
                          padding: const EdgeInsets.all(10),
                          children: [
                            _buildAnimatedDashboardCard(
                              icon: Icons.notifications_active,
                              label: 'Notify\n Absence',
                              onTap: () async {
                                setState(() => _isLoading = true);
                                await Future.delayed(const Duration(milliseconds: 300));
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          AttendanceForm(parentId: widget.parentId),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(opacity: animation, child: child);
                                      },
                                    ),
                                  );
                                }
                              },
                            ),
                            _buildAnimatedDashboardCard(
                              icon: Icons.edit,
                              label: 'Update\n Details',
                              onTap: () async {
                                setState(() => _isLoading = true);
                                await Future.delayed(const Duration(milliseconds: 300));
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          StudentHealthDetails(parentId: widget.parentId),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(1.0, 0.0),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Image Gallery Section
                      _buildImageGallery(),
                      const SizedBox(height: 10),
                      // Motivational Quotes Section
                      _buildMotivationalQuotes(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: const Color.fromARGB(137, 57, 55, 55),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // New method to build image gallery with transition effects
 Widget _buildImageGallery() {
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          for (int i = 0; i < _imageAssets.length; i++)
            AnimatedOpacity(
        duration: const Duration(milliseconds: 800),
        opacity: _currentImageIndex == i ? 1.0 : 0.0,
        child: AnimatedAlign(
          alignment: _currentImageIndex == i ? Alignment.center : Alignment.centerRight,
          duration: const Duration(milliseconds: 800),
          child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      _imageAssets[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          // Add image indicators
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _imageAssets.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  //margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalQuotes() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade100.withOpacity(0.5),
                Colors.purple.shade200.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inspiration Corner',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _motivationalQuotes[DateTime.now().millisecondsSinceEpoch % _motivationalQuotes.length],
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.purple.shade900,
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
      
        Hero(
          tag: 'registerButton',
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegisterNewStudent(parentId: widget.parentId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 3,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'New Child',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout,size: 28.0, color: Color.fromARGB(255, 255, 17, 0)),
          onPressed: _showLogoutDialog,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.5, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      )),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(221, 69, 10, 63),
        ),
      ),
    );
  }

  Widget _buildAnimatedDashboardCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 200),
          tween: Tween<double>(begin: 1, end: 1),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Card(
            //margin: const EdgeInsets.all(8.0),
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color.fromARGB(255, 139, 111, 193), Color.fromARGB(255, 140, 77, 151)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 30, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}