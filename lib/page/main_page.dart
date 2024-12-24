import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String custId = "";       // 관리 번호
  String hexCustName = "";  // 관리명 (hexadecimal)
  String custName = "";     // 관리명 (decode)
  bool inGuard = false;      // 경계 = true, 해제 = false

  // 현재 상태 불러오기
  Future<void> _loadStatusInfo() async {
    final response = await http.get(Uri.parse(""));
    final Map<String, dynamic> jsonData = jsonDecode(response.body);

    // 배열 길이 만큼 반복
    // id, name은 배열로 선언 해줘야 할 듯
    for (int i = 0; i < jsonData['Data'].length; i++) {
      setState(() {
        custId = jsonData['Data']['CustID'];
        hexCustName = jsonData['Data']['CustName'];
        inGuard = jsonData['Data']['InGuard'];
      });
    }
  }
  // 현재 상태 불러오기

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return MaterialApp(
      home: Scaffold(
        body: Text("Hello World"),
      ),
    );
  }
}
