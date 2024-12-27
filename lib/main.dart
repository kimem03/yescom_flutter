import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yescom_front/page/login_page.dart';

import 'api/fcm_service.dart';
import 'providers/user_info.dart';  // 전역 변수 import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화

  FcmService fcmService = FcmService();
  fcmService.getDeviceToken();

  // runApp(MyApp());
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserInfo(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
        ),
      ),
      home: LoginPage(),
    );
  }
}
