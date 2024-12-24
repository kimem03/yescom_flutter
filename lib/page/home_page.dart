import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'bell_page.dart';
import 'main_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
  }

  int _currentIndex = 0;

  final List<Widget> _pages = [const MainPage(), const BellPage()];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image.asset('assets/slice/home_on.png'),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/slice/bell_on.png'),
            label: '알림',
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        backgroundColor: const Color.fromRGBO(0, 93, 171, 1),
        unselectedItemColor: const Color.fromRGBO(204, 204, 204, 0),
        onTap: _onItemTapped,
      ),
    );
  }
}
