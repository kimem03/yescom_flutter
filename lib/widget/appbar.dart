import 'package:flutter/material.dart';

class Appbar extends StatelessWidget {
  const Appbar({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/slice/top_bg.png',),
            Image.asset('assets/slice/top_logo02.png', width: size.width*0.6,)
          ]
      ),
    );
  }
}
