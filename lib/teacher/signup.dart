import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:KinderConnect/widgets/custom_scaffold.dart';
import 'package:flutter/material.dart';

class TeacherSignUpScreen extends StatefulWidget {
  const TeacherSignUpScreen({super.key});

  @override
  State<TeacherSignUpScreen> createState() => _TeacherSignUpScreenState();
}

class _TeacherSignUpScreenState extends State<TeacherSignUpScreen> {
  final _formTeacherSignUpKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _teacherIdController = TextEditingController();
  bool agreePersonalData = true;

  // Firestore instance
  final CollectionReference teachersRef = FirebaseFirestore.instance.collection('Teachers');

  // Function to store data into Firestore
  Future<void> _onSignUp() async {
    if (_formTeacherSignUpKey.currentState!.validate() && agreePersonalData) {
      try {
        // Check if username or Teacher ID already exists
      QuerySnapshot querySnapshot = await teachersRef
          .where('username', isEqualTo: _usernameController.text) 
          .get();

      QuerySnapshot querySnapshot2 = await teachersRef 
          .where('teacher_id', isEqualTo: _teacherIdController.text)
          .get();

      if (querySnapshot.docs.isNotEmpty || querySnapshot2.docs.isNotEmpty) {
        // Username or Teacher ID already exists
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher ID or username already exists.')),
        );
        return;
      }

        // Creating a document in the 'Teachers' collection with form data
        await teachersRef.add({
          'username': _usernameController.text,
          'teacher_id': _teacherIdController.text,
          'password': _passwordController.text, // You might want to hash the password for security
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully Signed Up')),
        );
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
                color: Color.fromARGB(255, 128, 225, 141),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formTeacherSignUpKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Teacher Sign Up',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: Color.fromARGB(255, 0, 0, 0),
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
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
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
                      const SizedBox(height: 25.0),
                      // Teacher ID
                      TextFormField(
                        controller: _teacherIdController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Teacher ID';
                          } else if (!RegExp(r'^KC\d{4}$').hasMatch(value)) {
                            return 'Invalid Teacher ID. Please validate the ID with the kindergarten management.';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('Teacher ID'),
                          prefixIcon: const Icon(Icons.numbers),
                          hintText: 'Enter your valid Teacher ID',
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
                      const SizedBox(height: 25.0),
                      // Sign up button
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
