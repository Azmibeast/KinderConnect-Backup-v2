import 'package:KinderConnect/Parent/forgetpassword.dart';
import 'package:KinderConnect/Parent/home/homecontent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:KinderConnect/Parent/signup.dart';
import 'package:KinderConnect/widgets/custom_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _formParentLoginKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLoginInfo();
  }

  // Load saved login information if available
  Future<void> _loadSavedLoginInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedUsername = prefs.getString('savedParentUsername');
    final String? savedPassword = prefs.getString('savedParentPassword');
    if (savedUsername != null && savedPassword != null) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  // Function to check credentials
  Future<void> _login() async {
    if (_formParentLoginKey.currentState!.validate()) {
      try {
        // Accessing the Firestore collection 'Parents'
        final parentsRef = FirebaseFirestore.instance.collection('Parents');

        // Querying the Firestore to find a matching username and password
        final querySnapshot = await parentsRef
            .where('username', isEqualTo: _usernameController.text)
            .where('password', isEqualTo: _passwordController.text)
            .get();

        // Check if the query returned any documents
        if (querySnapshot.docs.isNotEmpty) {
          // If "Remember Me" is checked, save credentials
          if (_rememberMe) {
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('savedParentUsername', _usernameController.text);
            await prefs.setString('savedParentPassword', _passwordController.text);
          } else {
            // Clear saved credentials if "Remember Me" is unchecked
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.remove('savedParentUsername');
            await prefs.remove('savedParentPassword');
          }

          // Get the parent document ID (acting as Parent ID)
          final parentDoc = querySnapshot.docs.first;
          final parentId = parentDoc.id;

          // Navigate to the homepage with the parentId
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(parentId: parentId), // Pass the parentId to HomePage
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid username or password')),
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
            child: SizedBox(height: 10),
          ),
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: Form(
                key: _formParentLoginKey,
                child: ListView(
                  children: [
                    const Text(
                      'Parent Login',
                      style: TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Username Field
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
                        hintText: 'Enter Username',
                        hintStyle: const TextStyle(color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Password Field
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
                        hintText: 'Enter Password',
                        hintStyle: const TextStyle(color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),

                    // Log In Button
                    SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.purple], // You can change these colors
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20), // Optional: round the edges
                          ),
                          child: ElevatedButton(
                            onPressed: _login,
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
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),

                    const SizedBox(height: 10),
                    // Sign Up Prompt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don\'t have an account?',
                          style: TextStyle(color: Colors.black),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ParentSignUpScreen()),
                            );
                          },
                          child: const Text(
                            ' Sign Up',
                            style: TextStyle(color: Colors.blue),
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
