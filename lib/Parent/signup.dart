import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:KinderConnect/widgets/custom_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For storing parentId locally

class ParentSignUpScreen extends StatefulWidget {
  const ParentSignUpScreen({super.key});

  @override
  State<ParentSignUpScreen> createState() => _ParentSignUpScreenState();
}

class _ParentSignUpScreenState extends State<ParentSignUpScreen> {
  final _formParentSignUpKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool agreePersonalData = true;

  // Firestore instance
  final CollectionReference parentsRef = FirebaseFirestore.instance.collection('Parents');

  // Function to store data into Firestore
  Future<void> _onSignUp() async {
    if (_formParentSignUpKey.currentState!.validate() && agreePersonalData) {
      try {
        // Check if the username or email already exists in Firestore
      QuerySnapshot querySnapshot = await parentsRef
          .where('username', isEqualTo: _usernameController.text)
          .get();

      QuerySnapshot emailSnapshot = await parentsRef
          .where('email', isEqualTo: _emailController.text)
          .get();

      if (querySnapshot.docs.isNotEmpty || emailSnapshot.docs.isNotEmpty) {
        // Username or email already exists
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username or email already exists.')),
        );
        return; // Stop execution if a duplicate is found
      }

        // Generate a parentId based on the email or username
        String parentId = _emailController.text.split('@')[0]; // You can also use _usernameController.text

        // Store the parent details in Firestore
        await parentsRef.doc(parentId).set({
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text, // You might want to hash the password for security
          'parentId': parentId, // Store the generated parentId
        });

        // Save parentId locally for future use (e.g., during login or attendance submission)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('parentId', parentId); // Save parentId locally

        _showSuccessDialog();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else if (!agreePersonalData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the processing of personal data')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.fromARGB(255, 237, 236, 240), Color.fromARGB(255, 229, 199, 235)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color.fromARGB(255, 12, 192, 45),
                  size: 60,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Success!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your Account has been created. Please login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 7, 147, 33),
                    foregroundColor: const Color.fromARGB(255, 245, 244, 247),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formParentSignUpKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Parent Sign Up',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      // Username
                      TextFormField(
                        controller: _usernameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter Username';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('Username'),
                          prefixIcon: const Icon(Icons.person),
                          hintText: 'Enter Username',
                          hintStyle: const TextStyle(
                            color: Colors.black26,
                          ),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      // Email
                      TextFormField(
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('Email'),
                          prefixIcon: const Icon(Icons.email),
                          hintText: 'Enter Email',
                          hintStyle: const TextStyle(
                            color: Colors.black26,
                          ),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      // Password
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
                          hintStyle: const TextStyle(
                            color: Colors.black26,
                          ),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        obscuringCharacter: '*',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          } else if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('Confirm Password'),
                          prefixIcon: const Icon(Icons.lock),
                          hintText: 'Confirm Password',
                          hintStyle: const TextStyle(
                            color: Colors.black26,
                          ),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      // Sign up button
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
                            onPressed: _onSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent, // Set to transparent to allow gradient to show
                              shadowColor: Colors.transparent, // Remove shadow
                            ),
                            child: const Text('Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                            ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
