import 'package:flutter/material.dart';
import 'package:ifoot_academy/Pages/Back-office/backend_template.dart';

class SwitchingSplash extends StatelessWidget {
  final String switchingTo;

  const SwitchingSplash({Key? key, required this.switchingTo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _SwitchingSplashBody(switchingTo: switchingTo);
  }
}

class _SwitchingSplashBody extends StatefulWidget {
  final String switchingTo;

  const _SwitchingSplashBody({Key? key, required this.switchingTo}) : super(key: key);

  @override
  __SwitchingSplashBodyState createState() => __SwitchingSplashBodyState();
}

class __SwitchingSplashBodyState extends State<_SwitchingSplashBody> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _textAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _logoAnimation = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1.9 * 3.14159).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _textAnimation = Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pop(context); // Return after the animation ends
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
    return TemplatePageBack(
      title: "",
      body: Stack(
        children: [
          Center(
            child: ScaleTransition(
              scale: _logoAnimation,
              child: RotationTransition(
                turns: _rotationAnimation,
                child: Image.asset(
                  widget.switchingTo == 'coach'
                      ? 'assets/Logo/logo.png' // Path to your coach logo
                      : 'assets/Logo/logo.png', // Path to your player logo
                  width: 150,
                  height: 150,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 300.0),
              child: SlideTransition(
                position: _textAnimation,
                child: const Text(
                  'Switching',
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
