import 'package:flutter/material.dart';

class NavigateButton extends StatelessWidget {
  const NavigateButton({super.key, required this.onTap});
  final Widget? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (e)=> onTap!,
          ),
        );
      },
    );
  }
}
