import 'package:flutter/material.dart';

class Footer extends StatefulWidget {
  final int currentIndex; // Accept the current index as a parameter

  const Footer({Key? key, required this.currentIndex}) : super(key: key); // Constructor

  @override
  _FooterState createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex; // Initialize with passed current index
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.grey[850], // Modern dark grey background
      selectedItemColor: Colors.blueAccent, // Modern blue accent for selected items
      unselectedItemColor: Colors.white70, // Light grey for unselected items
      currentIndex: _currentIndex, // Set the selected index
      showUnselectedLabels: true,
      elevation: 10, // Adds elevation for a modern effect
      iconSize: 28, // Slightly larger icons for a sleek feel
      selectedFontSize: 14, // Modern font size for selected items
      unselectedFontSize: 12, // Slightly smaller font for unselected items
      items: const [
                BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Acceuil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Utilisateur',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'Groupes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event),
          label: 'Calendrier',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Training',
        ),
      ],
      onTap: (int index) {
        setState(() {
          _currentIndex = index;
        });

        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/admin');
            break;
          case 1:
            Navigator.pushNamed(context, '/manageUsers');
            break;
          case 2:
            Navigator.pushNamed(context, '/manageGroups');
            break;
          case 3:
            Navigator.pushNamed(context, '/manageEvents');
            break;
          case 4:
            Navigator.pushNamed(context, '/manageTraining');
            break;
        }
      },
    );
  }
}
