import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class PlanClassActivitiesForm extends StatefulWidget {
  final String teacherId;

  const PlanClassActivitiesForm({Key? key, required this.teacherId}) : super(key: key);

  @override
  State<PlanClassActivitiesForm> createState() => _PlanClassActivitiesFormState();
}

class _PlanClassActivitiesFormState extends State<PlanClassActivitiesForm> with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();
  DateTime? _selectedDate;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  // Add form key for validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _activityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2025),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      
      // Add subtle animation
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> _saveClassActivity() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('class_activities').add({
        'date': _selectedDate,
        'title': _titleController.text,
        'activity': _activityController.text,
        'created_at': Timestamp.now(),
        'isArchived': false,
        'teacherId': widget.teacherId,
        'parentArchives': {},
      });

      // Add success animation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Activity planned successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        setState(() {
          _selectedDate = null;
          _titleController.clear();
          _activityController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Plan Class Activities',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Date Selection Section
                          _buildDateSection(),
                          const SizedBox(height: 24),

                          // Title Input Section
                          _buildTitleInput(),
                          const SizedBox(height: 24),

                          // Activity Details Section
                          _buildActivityInput(),
                          const SizedBox(height: 32),

                          // Submit Button
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null
                      ? 'Choose a date'
                      : DateFormat('EEEE, d MMMM, y').format(_selectedDate!),
                  style: TextStyle(
                    color: _selectedDate == null ? Colors.grey : Colors.black87,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleInput() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Activity Title',
        hintText: 'Enter the title of your activity',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(
          Icons.title,
          color: Theme.of(context).primaryColor,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an activity title';
        }
        return null;
      },
    );
  }

  Widget _buildActivityInput() {
    return TextFormField(
      controller: _activityController,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: 'Activity Details',
        hintText: 'Describe the activity details...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter activity details';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveClassActivity,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 86, 19, 98),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Save Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}