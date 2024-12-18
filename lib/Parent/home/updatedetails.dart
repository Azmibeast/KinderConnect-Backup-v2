import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

class StudentHealthDetails extends StatefulWidget {
  final String parentId;

  const StudentHealthDetails({Key? key, required this.parentId}) : super(key: key);

  @override
  _StudentHealthDetailsState createState() => _StudentHealthDetailsState();
}

class _StudentHealthDetailsState extends State<StudentHealthDetails> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _healthStatusController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedFile;
  String? _currentHealthDoc;
  File? _profileImage;
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female'];
  String? _currentProfileImageUrl;
  String? _selectedStudentId;
  List<DocumentSnapshot> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('parent_id', isEqualTo: widget.parentId)
          .where('isApproved', isEqualTo: true)
          .get();

      setState(() {
        _students = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching students: $e')),
      );
    }
  }

  Future<void> _loadStudentDetails(String studentId) async {
    try {
      DocumentSnapshot student = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();

      if (student.exists) {
        Map<String, dynamic> data = student.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _dobController.text = data['date_of_birth'] ?? '';
          _selectedGender = data['gender'];
          _emergencyContactController.text = data['emergencyContact'] ?? '';
          _allergiesController.text = data['allergies'] ?? '';
          _healthStatusController.text = data['healthStatus'] ?? '';
          _addressController.text = data['address'] ?? '';
          _currentProfileImageUrl = data['profile_image'];
          _currentHealthDoc = data['healthDocument'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading student details: $e')),
      );
    }
  }

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

  void _viewImage() {
  if (_profileImage != null || _currentProfileImageUrl != null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Profile Image'),
            backgroundColor: const Color.fromARGB(255, 243, 175, 254),
          ),
          body: Column(
            children: [
              Expanded(
                child: PhotoView(
                  backgroundDecoration: const BoxDecoration(color: Colors.white),
                  imageProvider: _profileImage != null
                      ? FileImage(_profileImage!)
                      : NetworkImage(_currentProfileImageUrl!) as ImageProvider,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage();
                },
                icon: const Icon(Icons.edit, color: Colors.white,),
                label: const Text('Change Image', style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 86, 0, 99),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _selectedFile = result.files.single.path;
      });
    }
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

  Future<void> _updateStudentDetails() async {
    if (_formKey.currentState!.validate() && _selectedStudentId != null) {
      try {
        String? imageUrl = _currentProfileImageUrl;
        String? healthDocUrl = _currentHealthDoc;

        // Upload new profile image if selected
        if (_profileImage != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images/${_nameController.text}.jpg');
          await storageRef.putFile(_profileImage!);
          imageUrl = await storageRef.getDownloadURL();
        }

        // Upload new health document if selected
        if (_selectedFile != null) {
          final healthDocRef = FirebaseStorage.instance
              .ref()
              .child('health_documents/${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.split('/').last}');
          await healthDocRef.putFile(File(_selectedFile!));
          healthDocUrl = await healthDocRef.getDownloadURL();
        }

        // Update student details in Firestore
        await FirebaseFirestore.instance
            .collection('students')
            .doc(_selectedStudentId)
            .update({
          'name': _nameController.text,
          'date_of_birth': _dobController.text,
          'gender': _selectedGender,
          'emergencyContact': _emergencyContactController.text,
          'allergies': _allergiesController.text,
          'healthStatus': _healthStatusController.text,
          'healthDocument': healthDocUrl,
          'profile_image': imageUrl,
          'address': _addressController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Row(
      children: [
        // Rotating success icon
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 800),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.rotate(
              angle: value * 2 * 3.14,
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
              ),
            );
          },
        ),
         const SizedBox(width: 12),
         const Text('Student details updated successfully!'),
      ],
    ),
    backgroundColor: Colors.green,
  ),
);
          
      
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating details: $e')),
        );
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 140, 77, 151),
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      title: const Text('Update Child\'s Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),),
      leading: Hero(
        tag: 'back_button',
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    body: AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
             Color.fromARGB(255, 158, 142, 191),
             Color.fromARGB(255, 237, 223, 240),
          ],
          stops: [0.0, 1.0],
        ),
      ),
      child: _isLoading
          ? Center(
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  );
                },
              ),
            )
          : SafeArea(
              child: _students.isEmpty
                  ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 15),
              const Text(
                'You don\'t have any child registered yet!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please register your child first.',
                style: TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        )

              : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      
                      // Main Form Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Padding(
                            padding: const EdgeInsets.all(25),
                            child: Column(
                              children: [

                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedStudentId,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Select Child',
                                      labelStyle: const TextStyle(color: Color.fromARGB(255, 86, 0, 99)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color.fromARGB(255, 86, 0, 99)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: const Color.fromARGB(255, 86, 0, 99).withOpacity(0.5)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color.fromARGB(255, 86, 0, 99), width: 2),
                                      ),
                                      prefixIcon: const Icon(Icons.child_care, color: Color.fromARGB(255, 86, 0, 99)),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    items: _students.map((student) {
                                      return DropdownMenuItem<String>(
                                        value: student.id,
                                        child: Text(student['name']),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedStudentId = newValue;
                                      });
                                      if (newValue != null) {
                                        _loadStudentDetails(newValue);
                                      }
                                    },
                                    validator: (value) => value == null ? 'Please select a child' : null,
                                  ),
                                ),

                                const SizedBox(height: 25),
                                // Profile Image Section
                                Hero(
                                  tag: 'profile_image',
                                  child: GestureDetector(
                                    onTap: () {
                                            if (_profileImage != null || _currentProfileImageUrl != null) {
                                              _viewImage();
                                            } else {
                                              _pickImage();
                                            }
                                          },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color.fromARGB(255, 86, 0, 99).withOpacity(0.3),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.grey[200],
                                        backgroundImage: _profileImage != null
                                            ? FileImage(_profileImage!)
                                            : (_currentProfileImageUrl != null
                                                ? NetworkImage(_currentProfileImageUrl!)
                                                : null) as ImageProvider?,
                                        child: _profileImage == null && _currentProfileImageUrl == null
                                            ? Icon(
                                                Icons.add_a_photo,
                                                size: 35,
                                                color: Colors.grey[400],
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 25),

                                // Form Fields with Staggered Animation
                                ..._buildStaggeredFormFields(),

                                const SizedBox(height: 30),

                                // Animated Submit Button
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255, 86, 0, 99),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 5,
                                    ),
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        _updateStudentDetails();
                                      }
                                    },
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children:  [
                                        Icon(Icons.update, color: Colors.white),
                                        SizedBox(width: 10),
                                        Text(
                                          'Update Details',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    ),
  );
}

// Helper method to build staggered form fields
List<Widget> _buildStaggeredFormFields() {
  final fields = [
    _buildAnimatedField(
      child: TextFormField(
        controller: _nameController,
        decoration: _getInputDecoration(
          'Student Name',
          Icons.person,
        ),
        validator: (value) => value?.isEmpty ?? true ? 'Please enter the student\'s name' : null,
      ),
    ),
    _buildAnimatedField(
      child: TextFormField(
        controller: _dobController,
        decoration: _getInputDecoration(
          'Date of Birth',
          Icons.calendar_today,
        ),
        readOnly: true,
        onTap: () => _pickDateOfBirth(context),
        validator: (value) => value?.isEmpty ?? true ? 'Please select the date of birth' : null,
      ),
    ),
    _buildAnimatedField(
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: _getInputDecoration(
          'Gender',
          Icons.wc,
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
        validator: (value) => value == null ? 'Please select the gender' : null,
      ),
    ),
    // Add more form fields here...
_buildAnimatedField(
      child: TextFormField(
                          controller: _emergencyContactController,
                          decoration: const InputDecoration(
                            labelText: 'Emergency Contact Number*',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter emergency contact number';
                            }
                            return null;
                          },
                        ),
),

_buildAnimatedField(
      child: TextFormField(
                          controller: _allergiesController,
                          decoration: const InputDecoration(
                            labelText: 'Allergies (if any)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.medical_services),
                          ),
                        ),
),

_buildAnimatedField(
      child: TextFormField(
                          controller: _healthStatusController,
                          decoration: const InputDecoration(
                            labelText: 'Health Status',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.health_and_safety),
                          ),
                        ),
),

_buildAnimatedField(
      child: TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.home),
                          ),
                        ),
),

_buildAnimatedField(
      child: OutlinedButton.icon(
                          icon: const Icon(Icons.attach_file),
                          label: Text(_selectedFile != null
                              ? 'File: ${_selectedFile!.split('/').last}'
                              : _currentHealthDoc != null
                                  ? 'Current health document exists'
                                  : 'Attach Health Document'),
                          onPressed: _pickFile,
                        ),
),

  ];

  return fields;
}

// Helper method for animated form fields
Widget _buildAnimatedField({required Widget child}) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 500),
    builder: (context, value, child) {
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: child,
    ),
  );
}

// Helper method for consistent input decoration
InputDecoration _getInputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color.fromARGB(255, 86, 0, 99)),
    prefixIcon: Icon(icon, color: const Color.fromARGB(255, 86, 0, 99)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color.fromARGB(255, 86, 0, 99)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: const Color.fromARGB(255, 86, 0, 99).withOpacity(0.5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color.fromARGB(255, 86, 0, 99), width: 2),
    ),
    filled: true,
    fillColor: Colors.white,
  );
}
}