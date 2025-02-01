import 'package:flutter/material.dart';

class Footer extends StatefulWidget {
  final int currentIndex;
  final bool isCoach;

  const Footer({Key? key, required this.currentIndex, required this.isCoach})
      : super(key: key);

  @override
  _FooterState createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.grey[850],
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.white70,
      currentIndex: _currentIndex,
      showUnselectedLabels: true,
      elevation: 10,
      iconSize: 28,
      selectedFontSize: 14,
      unselectedFontSize: 12,
      items: widget.isCoach
          ? const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
             BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Coachs'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.schedule), label: 'Plannings'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart), label: 'Statistiques'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.message), label: 'Communication'),
            ]
          : const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Utilisateurs'),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groupes'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.event), label: 'Événements'),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            ],
      onTap: (int index) {
        setState(() {
          _currentIndex = index;
        });

        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(
              context,
              '/admin',
              arguments: {'isCoach': widget.isCoach},
            );
            break;
          case 1:
            Navigator.pushNamed(
              context,
              widget.isCoach ? '/AllCoaches' : '/manageUsers',
            );
            break;
          case 2:
            Navigator.pushNamed(
              context,
              widget.isCoach ? '/PlanningOverview' : '/manageGroups',
            );
            break;
          case 3:
            Navigator.pushNamed(
              context,
              widget.isCoach ? '/coachStats' : '/manageEvents',
            );
            break;
          case 4:
            if (!widget.isCoach) {
              Navigator.pushNamed(context, '/chatOptions');
            }
            break;
        }
      },
    );
  }
}
