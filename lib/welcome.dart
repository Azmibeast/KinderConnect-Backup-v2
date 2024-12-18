import 'package:KinderConnect/Parent/login.dart';
import 'package:KinderConnect/teacher/login.dart';
import 'package:KinderConnect/widgets/custom_buttom.dart';
import 'package:KinderConnect/widgets/custom_scaffold.dart';
import 'package:flutter/material.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          Flexible(
            flex: 8,
              child: Container(
            child: Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'K',
                        style: TextStyle(
                          fontSize: 1.0,
                          fontWeight: FontWeight.w600,
                        )),


                    ]
                  ),
                )),
          )),
          const Flexible(
            flex: 1,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  children: [
                    Expanded(
                      child: WelcomeButton(
                        buttonText: 'Parent',
                        onTap: ParentLoginScreen(),
                        color: Colors.white,
                        textColor: Colors.black,
                      ),
                ),
                    Expanded(
                      child: WelcomeButton(
                        buttonText: 'Teacher',
                        onTap: TeacherLoginScreen(),
                        color: Color.fromARGB(255, 128, 225, 141),
                        textColor: Color.fromARGB(255, 0, 0, 0),
                      ),
                )
                
                  ],
                ),
              ),
          )
        ],
      ),
    );

  }
}
