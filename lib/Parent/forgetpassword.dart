import 'package:KinderConnect/widgets/custom_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Firestore instance to interact with the database
  final CollectionReference parentsRef = FirebaseFirestore.instance.collection('Parents');

  bool _emailExists = false;
  String? _documentId;

  Future<void> _checkEmail() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Fetch the parent document with the entered email
        final QuerySnapshot snapshot = await parentsRef
            .where('email', isEqualTo: _emailController.text.trim())
            .get();

        if (snapshot.docs.isNotEmpty) {
          setState(() {
            _emailExists = true;
            _documentId = snapshot.docs.first.id;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email found. Please enter a new password.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email not found')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text == _confirmPasswordController.text) {
        try {
          // Update the password in Firestore
          if (_documentId != null) {
            await parentsRef.doc(_documentId).update({
              'password': _newPasswordController.text.trim(),
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password reset successful')),
            );

            // Clear the fields and reset state
            _emailController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
            setState(() {
              _emailExists = false;
            });
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
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
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Email field
              if (!_emailExists) ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
            onPressed: _checkEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, // Set to transparent to allow gradient to show
              shadowColor: Colors.transparent, // Remove shadow
            ),
            child: const Text('Verify Email',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
            ),
          ),
        ),
      ),
              ] else ...[
                // New Password field
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Confirm Password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
            onPressed: _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, // Set to transparent to allow gradient to show
              shadowColor: Colors.transparent, // Remove shadow
            ),
            child: const Text('Reset Password',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
            ),
          ),
        ),
      ),
              ],
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
