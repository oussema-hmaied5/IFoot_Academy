import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../models/app_state.dart';

class DrawerBApp extends StatelessWidget {
  const DrawerBApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height * 0.15,
            child: DrawerHeader(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              margin: const EdgeInsets.only(bottom: 0.0),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/profile');
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xff7eed9d),
                      child: Text(
                        StoreProvider.of<AppState>(context).state.user?.name[0] ?? '',
                        style: const TextStyle(
                          fontFamily: 'FontB',
                          fontSize: 19,
                          color: Color(0xaa003542),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  Expanded(
                    child: GestureDetector(  // Add GestureDetector here
                      onTap: () {
                        Navigator.of(context).pushNamed('/profile');
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          ' ${StoreProvider.of<AppState>(context).state.user?.name ?? ''}',
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 65,
                  ),
                  GestureDetector(
                    child: const Icon(
                      Icons.logout_rounded,
                    ),
                    onTap: () {
                      StoreProvider.of<AppState>(context).dispatch(SignOut());
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            height: 0,
            thickness: 2.5,
            color: Color(0x337eed9d),
            endIndent: 15,
            indent: 15,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.025,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 7,
                horizontal: 30,
              ),
              child: Row(
                children: [
                  const Icon(Icons.supervised_user_circle_rounded, color: Color(0xff003542)),
                  TextButton(
                    onPressed: () {
                      // Define and dispatch the appropriate action for teams if needed
                    },
                    child: const Text(
                      'Teams',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: 'FontR',
                        fontSize: 23,
                        color: Color(0xff003542),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
 Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 7,
                horizontal: 30,
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.sportscourt_fill, color: Color(0xff003542)),
                  TextButton(
                    onPressed: () {
                    },
                    child: const Text(
                      'Stadiums',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: 'FontR',
                        fontSize: 23,
                        color: Color(0xff003542),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 7,
                horizontal: 30,
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle_rounded, color: Color(0xff003542)),
                  TextButton(
                    onPressed: () {
                      // Define and dispatch the appropriate action for players if needed
                    },
                    child: const Text(
                      'Players',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: 'FontR',
                        fontSize: 23,
                        color: Color(0xff003542),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 7,
                horizontal: 30,
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_soccer_rounded, color: Color(0xff003542)),
                  TextButton(
                    onPressed: () {
                      // Define and dispatch the appropriate action for top scorers if needed
                    },
                    child: const Text(
                      'Top Scorers',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: 'FontR',
                        fontSize: 23,
                        color: Color(0xff003542),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 7,
                horizontal: 30,
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xff003542)),
                  TextButton(
                    onPressed: () {
                      // Define and dispatch the appropriate action for best matches if needed
                    },
                    child: const Text(
                      'Best Matches',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: 'FontR',
                        fontSize: 23,
                        color: Color(0xff003542),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 7,
                horizontal: 30,
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports, color: Color(0xff003542)),
                  TextButton(
                    onPressed: () {
                      // Define and dispatch the appropriate action for referees if needed
                    },
                    child: const Text(
                      'Referees',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: 'FontR',
                        fontSize: 23,
                        color: Color(0xff003542),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
           Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 7,
                horizontal: 30,
              ),
              child: Row(
                children: [
                  const Icon(Icons.settings, color: Color(0xff003542)),
                  TextButton(
                    onPressed: () {
                      // Define and dispatch the appropriate action for settings if needed
                    },
                    child: const Text(
                      'Settings',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: 'FontR',
                        fontSize: 23,
                        color: Color(0xff003542),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      )
        );
  }
}

class SignOut {}
