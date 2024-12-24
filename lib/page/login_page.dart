import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: Scaffold(
            body: Container(
              margin: EdgeInsets.only(top: 50),
              alignment: Alignment.center,
              child: Image.asset('assets/slice/login_logo.png'),
            ),
          ),
        ),
        body: Text("Test HI"),
      ),
    );
  }
}
