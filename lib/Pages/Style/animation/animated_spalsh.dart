import 'package:flutter/material.dart';

class AnimatedSplash extends StatelessWidget {
  final VoidCallback onAnimationComplete;

  const AnimatedSplash({Key? key, required this.onAnimationComplete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _AnimatedSplashBody(onAnimationComplete: onAnimationComplete);
  }
}

class _AnimatedSplashBody extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const _AnimatedSplashBody({Key? key, required this.onAnimationComplete}) : super(key: key);

  @override
  __AnimatedSplashBodyState createState() => __AnimatedSplashBodyState();
}

class __AnimatedSplashBodyState extends State<_AnimatedSplashBody> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<Offset> _textAnimation;

  @override
  void initState() {
    super.initState();

    // Configure logo animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _logoAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Configure text animation
    _textAnimation = Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Trigger callback after animation ends
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: ScaleTransition(
              scale: _logoAnimation,
              child: Image.asset(
                'assets/Logo/logo.png', // Path to your logo
                width: 300,
                height: 250,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: SlideTransition(
                position: _textAnimation,
                child: const Text(
                  '11 ans de service',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
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
