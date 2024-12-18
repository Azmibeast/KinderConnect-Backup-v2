import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class RegisterNewStudent extends StatefulWidget {
  final String parentId;

  const RegisterNewStudent({Key? key, required this.parentId}) : super(key: key);

  @override
  _RegisterNewStudentPageState createState() => _RegisterNewStudentPageState();
}

class _RegisterNewStudentPageState extends State<RegisterNewStudent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  File? _profileImage;
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female'];

  // Your existing methods remain the same
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedImage = await picker.pickImage(source: ImageSource.camera);
                  if (pickedImage != null) {
                    setState(() {
                      _profileImage = File(pickedImage.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedImage = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedImage != null) {
                    setState(() {
                      _profileImage = File(pickedImage.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDateOfBirth(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      setState(() {
        _dobController.text = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Success'),
            ],
          ),
          content: const Text('Student registration Application submitted!\nPlease wait for the approval status'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to previous screen
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveToFirestore() async {
    if (_formKey.currentState!.validate()) {
    try {
      // Check if a student with the same name already exists for the same parent
      final querySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('name', isEqualTo: _nameController.text)
          .where('parent_id', isEqualTo: widget.parentId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // If a student with the same name exists, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student with this name already exists.'),
            
            ),
        );
        return;
      }

      String? imageUrl;
      if (_profileImage != null) {
        // Upload the image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${_nameController.text}.jpg');
        await storageRef.putFile(_profileImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Save new student details to Firestore
      await FirebaseFirestore.instance.collection('students').add({
        'name': _nameController.text,
        'date_of_birth': _dobController.text,
        'address': _addressController.text,
        'gender': _selectedGender,
        'profile_image': imageUrl ?? 'No Image',
        'parent_id': widget.parentId,
        'isApproved': false,
        'status': 'pending',
      });

      /*ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student Details Submitted')),
      );*/
      _showSuccessDialog();

      // Reset the form after successful submission
      _formKey.currentState?.reset();
      _nameController.clear();
      _dobController.clear();
      _addressController.clear();
      setState(() {
        _selectedGender = null;
        _profileImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }// Your existing _saveToFirestore implementation remains the same
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Register New Child', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white,),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.blueGrey,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blueGrey, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Hero(
              tag: 'registerButton',
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Card(
                          color: const Color.fromARGB(255, 255, 254, 253),
                          margin: const EdgeInsets.fromLTRB(5.0, 20.0, 5.0, 180.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.grey[200],
                                      child: _profileImage != null
                                          ? ClipOval(
                                              child: Image.file(
                                                _profileImage!,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Icon(
                                              Icons.add_a_photo,
                                              size: 40,
                                              color: Colors.grey[600],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Flexible(
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        labelText: 'Child Name',
                                        prefixIcon: const Icon(Icons.person, color: Colors.blueGrey),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter the child\'s name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _dobController,
                                    decoration: InputDecoration(
                                      labelText: 'Date of Birth',
                                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.blueGrey),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    readOnly: true,
                                    onTap: () => _pickDateOfBirth(context),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select the date of birth';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _addressController,
                                    decoration: InputDecoration(
                                      labelText: 'Address',
                                      prefixIcon: const Icon(Icons.location_on, color: Colors.blueGrey),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter the address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedGender,
                                    decoration: InputDecoration(
                                      labelText: 'Gender',
                                      prefixIcon: const Icon(Icons.wc, color: Colors.blueGrey),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    items: _genders.map((String gender) {
                                      return DropdownMenuItem<String>(
                                        value: gender,
                                        child: Text(gender),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedGender = newValue;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select the gender';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _saveToFirestore,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueGrey,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: const Text(
                                        'Submit',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
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
        ),
        resizeToAvoidBottomInset: true,
      ),
    );
  }
}