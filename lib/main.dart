import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:yescom_front/api/fcm_setting.dart';
import 'package:yescom_front/page/login_page.dart';

import 'api/fcm_service.dart';
import 'providers/user_info.dart';  // 전역 변수 import

Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  log('백그라운드 메시지 처리: ${message.notification!.body!}');
}

void initializeNotification() async {
  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

  final flutterLocalNotificationPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
  ?.createNotificationChannel(const AndroidNotificationChannel(
      'high_importance_channel', 'high_importance_notification', importance: Importance.max));
  await flutterLocalNotificationPlugin.initialize(const InitializationSettings(
    android: AndroidInitializationSettings("@mipmap/ic_launcher")
  ));
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화
  fcmSetting();
  initializeNotification();

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
