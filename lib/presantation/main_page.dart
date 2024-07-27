import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:ifoot_academy/models/app_state.dart';
import 'package:ifoot_academy/presantation/drawer.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    StoreProvider.of<AppState>(context).dispatch(SignOut());
    Navigator.of(context).pushReplacementNamed('/'); 
  }

  @override
  Widget build(BuildContext context) {
    final double _height = MediaQuery.of(context).size.height;
    final double _width = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Main Page'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      drawer: const DrawerApp(),
      body: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Container(
            color: const Color(0xff7eed9d),
            height: _height,
            width: _width,
            child: const Padding(
              padding: EdgeInsets.only(top: 100, left: 30),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 110, horizontal: _width * 0.05),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0x55ffffff),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              height: _height * 0.1,
              width: _width * 0.9,
              child: Padding(
                padding: const EdgeInsets.only(top: 5, left: 15, right: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Prochaine séance :',
                      style: TextStyle(
                        fontFamily: 'FontB',
                        color: Color(0xff003542),
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Text(
                          "Lundi 15H:30",
                          style: const TextStyle(
                            fontFamily: 'FontB',
                            color: Color(0xff003542),
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 200, horizontal: _width * 0.05),
            child: Row(
              children: const <Widget>[
                Text(
                  "N'oubliez pas :",
                  style: TextStyle(
                    fontFamily: 'FontB',
                    color: Color(0xff003542),
                    fontSize: 23,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 240, horizontal: _width * 0.05),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0x55ffffff),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              height: _height * 0.07,
              width: _width * 0.55,
              child: Padding(
                padding: const EdgeInsets.only(top: 5, left: 15, right: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "ahhahaa",
                      style: const TextStyle(
                        fontFamily: 'FontB',
                        color: Color(0xff003542),
                        fontSize: 20,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                    ),
                  
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: _height * 0.39),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xffffffff),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
                ),
                height: _height * 0.61,
                width: _width,
                child: Column(
                  children: [
                    const Padding(padding: EdgeInsets.all(10)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            setState(() {
                     //         StoreProvider.of<AppState>(context).dispatch((_onResultEchipe));
                            });
                          },
                          child: Container(
                            height: _height * 0.17,
                            width: _width * 0.4,
                            decoration: const BoxDecoration(
                              color: Color(0x07000000),
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const <Widget> [
                                Icon(Icons.supervised_user_circle_rounded,size: 50,color: Color(0xff7eed9d),),
                                Text(
                                  'Équipes',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontFamily: 'FontR',
                                    fontSize: 23,
                                    color: Color(0xff003542),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                    //        StoreProvider.of<AppState>(context).dispatch((_onResultStadioane));
                          },
                          child: Container(
                            height: _height * 0.17,
                            width: _width * 0.4,
                            decoration: const BoxDecoration(
                              color: Color(0x07000000),
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const <Widget> [
                                Icon(CupertinoIcons.sportscourt_fill,size: 50,color: Color(0xff7eed9d),),
                                Text(
                                  'Stades',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontFamily: 'FontR',
                                    fontSize: 23,
                                    color: Color(0xff003542),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(10)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            setState(() {
                             // StoreProvider.of<AppState>(context).dispatch(('~~~',_resultSub1));
                            });
                          },
                          child: Container(
                            height: _height * 0.17,
                            width: _width * 0.4,
                            decoration: const BoxDecoration(
                              color: Color(0x07000000),
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const <Widget> [
                                Icon(Icons.account_circle_rounded,size: 50,color: Color(0xff7eed9d),),
                                Text(
                                  'Joueurs',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontFamily: 'FontR',
                                    fontSize: 23,
                                    color: Color(0xff003542),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                          //  StoreProvider.of<AppState>(context).dispatch(('Atacant', _resultJoin3));
                          },
                          child: Container(
                            height: _height * 0.17,
                            width: _width * 0.4,
                            decoration: const BoxDecoration(
                              color: Color(0x07000000),
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const <Widget> [
                                Icon(Icons.sports_soccer_rounded,size: 50,color: Color(0xff7eed9d),),
                                Text(
                                  'Meilleurs buteurs',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontFamily: 'FontR',
                                    fontSize: 23,
                                    color: Color(0xff003542),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(10)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            setState(() {
                           //   StoreProvider.of<AppState>(context).dispatch((_resultJoin2));
                            });
                          },
                          child: Container(
                            height: _height * 0.17,
                            width: _width * 0.4,
                            decoration: const BoxDecoration(
                              color: Color(0x07000000),
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const <Widget> [
                                Icon(Icons.star_rounded,size: 50,color: Color(0xff7eed9d),),
                                Text(
                                  'Meilleurs matchs',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontFamily: 'FontR',
                                    fontSize: 23,
                                    color: Color(0xff003542),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                          //  StoreProvider.of<AppState>(context).dispatch((_resultJoin6));
                          },
                          child: Container(
                            height: _height * 0.17,
                            width: _width * 0.4,
                            decoration: const BoxDecoration(
                              color: Color(0x07000000),
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const <Widget> [
                                Icon(Icons.sports,size: 50,color: Color(0xff7eed9d),),
                                Text(
                                  'Entraineur',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontFamily: 'FontR',
                                    fontSize: 23,
                                    color: Color(0xff003542),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 93, left: 240),
            child: Container(
              height: 35,
              width: 35,
              child: FittedBox(
                child: Icon(
                  Icons.live_tv_rounded,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 224, left: 147),
            child: Container(
              height: 35,
              width: 35,
              child: FittedBox(
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.amberAccent,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 60, left: 10),
            child: Row(
              children: [
                SizedBox(
                  height: 50,
                  width: 50,
                  child: FittedBox(
                    child: IconButton(
                      onPressed: () => _scaffoldKey.currentState!.openDrawer(),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFFffffff),
                        size: 27,
                      ),
                    )
                  ),
                ),
                Expanded(child: Container(height: 50,),),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                    _signOut(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
