import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:yescom_front/providers/status_info.dart';

void fcmSetting() async {
  BuildContext? context;

  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true);

  // foreground에서의 푸시 알림 표시를 위한 알림 중요도 설정
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  // foreground에서의 푸시 알림 표시를 위한 local notifications 설정
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(), // iOS 초기화 설정 변경
    ),
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // 선택한 알림을 처리하는 코드 (필요한 경우 작성)
    },
  );

  // foreground 푸시 알림 핸들링
  FirebaseMessaging.onMessage.listen((RemoteMessage messages) {
    log("전송: ${messages.data}"); // 디버그용
    log("타입: ${messages.runtimeType}"); // 디버그용

    // data 필드(JSON 형식)
    String jsonData = jsonEncode(messages.data);
    log("Data as JSON String: $jsonData");

    messages.data.forEach((key, value) {
      String parsedValue = value.isNotEmpty ? value : '';
      log('Key: $key, Value: $parsedValue');
    });

    // data 필드에서 'Status' 값 확인
    if (messages.data['Status'] == '1') {
      // Status 값이 1이면 inGuard 값을 true로 설정
      final statusInfo = Provider.of<StatusInfo>(context!, listen: false); // StatusInfo 인스턴스를 가져옴
      statusInfo.setInGuard(true); // StatusInfo 인스턴스를 통해 상태 업데이트

      // SharedPreferences에 값 저장
      statusInfo.saveStatusInfo(messages.data['CustID']);
    }

    // 알림 처리 (기존 코드)
    String messageValue = messages.data['Message'] ?? 'Default message';
    RemoteNotification? notification = messages.notification;
    AndroidNotification? android = messages.notification?.android;
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        messageValue,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon,
          ),
        ),
      );
    }
  });
}
