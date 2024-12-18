import 'package:KinderConnect/teacher/home/teacherhomecontent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:KinderConnect/widgets/custom_scaffold.dart';
import 'package:KinderConnect/teacher/signup.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final _formTeacherLoginKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;

  // Firestore instance
  final CollectionReference teachersRef = FirebaseFirestore.instance.collection('Teachers');

  @override
  void initState() {
    super.initState();
    _loadSavedLoginInfo();
  }

  // Load saved login information if available
  Future<void> _loadSavedLoginInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedUsername = prefs.getString('savedUsername');
    final String? savedPassword = prefs.getString('savedPassword');
    if (savedUsername != null && savedPassword != null) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  // Function to check credentials
  Future<void> _onLogin() async {
    if (_formTeacherLoginKey.currentState!.validate()) {
      try {
        QuerySnapshot query = await teachersRef
            .where('username', isEqualTo: _usernameController.text)
            .where('password', isEqualTo: _passwordController.text)
            .get();

        if (query.docs.isNotEmpty) {

          String teacherId = query.docs.first.id;
          // If "Remember Me" is checked, save credentials
          if (_rememberMe) {
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('savedUsername', _usernameController.text);
            await prefs.setString('savedPassword', _passwordController.text);
          } else {
            // Clear saved credentials if "Remember Me" is unchecked
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.remove('savedUsername');
            await prefs.remove('savedPassword');
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherHomePage(teacherId: teacherId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid Username or Password')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          const Expanded(
            flex: 1,
            child: SizedBox(
              height: 10,
            ),
          ),
          Expanded(
  flex: 7,
  child: Container(
    padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
    decoration: const BoxDecoration(
      color: Color.fromARGB(255, 128, 225, 141),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(40.0),
        topRight: Radius.circular(40.0),
      ),
    ),
    child: Form(
      key: _formTeacherLoginKey,
      child: ListView(
        children: [
          const Text(
            'Teacher',
            style: TextStyle(
              fontSize: 30.0,
              fontWeight: FontWeight.w900,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Username input
          TextFormField(
            controller: _usernameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter Username';
              }
              return null;
            },
            decoration: InputDecoration(
              label: const Text('Username'),
              prefixIcon: const Icon(Icons.person),
              labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              hintText: 'Enter Username',
              hintStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Password input
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            obscuringCharacter: '*',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter Password';
              }
              return null;
            },
            decoration: InputDecoration(
              label: const Text('Password'),
              prefixIcon: const Icon(Icons.lock),
              labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              hintText: 'Enter Password',
              hintStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Remember Me checkbox
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (bool? value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
              const Text(
                'Remember Me',
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ],
          ),
          // Login button
          SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ Color.fromARGB(255, 0, 24, 44), Colors.purple], // You can change these colors
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20), // Optional: round the edges
          ),
          child: ElevatedButton(
            onPressed: _onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, // Set to transparent to allow gradient to show
              shadowColor: Colors.transparent, // Remove shadow
            ),
            child: const Text('Log In',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
            ),
          ),
        ),
      ),
          const SizedBox(height: 30),
          // Sign Up option
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Don\'t have an account?',
                style: TextStyle(color: Colors.black, fontSize: 20.0),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (e) => const TeacherSignUpScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ],
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
}
