import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize the AnimationController
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Navigate to the main screen after a delay
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed('/');
    });
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 213, 225, 247), Color.fromARGB(255, 231, 243, 243)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 2.0 * 3.14,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                 
                  child: Image.asset(
                    'assets/Logo/logo.png', // Ensure this path is correct
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20), // Add some space between the logo and the text
              const Text(
                'IFoot ',
                style: TextStyle(
                  fontSize: 28, // Adjust the font size as needed
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black38,
                      offset: Offset(3.0, 3.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
