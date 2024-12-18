import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlanSpecialEventForm extends StatefulWidget {
  const PlanSpecialEventForm({super.key});

  @override
  State<PlanSpecialEventForm> createState() => _PlanSpecialEventFormState();
}

class _PlanSpecialEventFormState extends State<PlanSpecialEventForm> {
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _eventTitleController.dispose();
    _eventDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2025),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5C6BC0),
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
    }
  }

  Future<void> _saveSpecialEvent() async {
    if (_selectedDate != null &&
        _eventTitleController.text.isNotEmpty &&
        _eventDescriptionController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance.collection('special_event').add({
          'date': _selectedDate,
          'title': _eventTitleController.text,
          'description': _eventDescriptionController.text,
          'created_at': Timestamp.now(),
        });

        // Show success animation
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF5C6BC0),
                        size: 64,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Event Planned Successfully!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _selectedDate = null;
                            _eventTitleController.clear();
                            _eventDescriptionController.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C6BC0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Continue', style: TextStyle(color: Colors.white),),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5C6BC0)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 173, 186, 222),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Plan Special Event',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Create a memorable event for everyone',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 106, 56, 193),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Main Form Card
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 204, 215, 238),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 5,
                          blurRadius: 15,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Selection
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F9),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: _selectedDate != null
                                    ? const Color(0xFF5C6BC0)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF5C6BC0),
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  _selectedDate == null
                                      ? 'Select Event Date'
                                      : DateFormat('EEEE, d MMMM y')
                                          .format(_selectedDate!),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedDate == null
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Event Title
                        TextFormField(
                          controller: _eventTitleController,
                          decoration: InputDecoration(
                            labelText: 'Event Title',
                            hintText: 'Enter the title of your event',
                            prefixIcon: const Icon(
                              Icons.event,
                              color: Color(0xFF5C6BC0),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F6F9),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Event Description
                        TextFormField(
                          controller: _eventDescriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Event Description',
                            hintText: 'Describe your event',
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(
                                Icons.description,
                                color: Color(0xFF5C6BC0),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F6F9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSpecialEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C6BC0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text(
                              'Plan Event',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}