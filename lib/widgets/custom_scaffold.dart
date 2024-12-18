import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  const CustomScaffold({super.key, this.child});
final Widget? child;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Image.asset(
            'assets/images/Backgroundimage1.png',

            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            //color: Colors.black.withOpacity(0.1),  // Dark overlay with opacity
          ),
          SafeArea(
            child: child!,
          ),
        ],
      ),
    );
  }
}
