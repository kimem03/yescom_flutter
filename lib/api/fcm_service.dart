import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> getDeviceToken() async {
    try {
      // 토큰 요청
      String? token = await _firebaseMessaging.getToken();

      // if (token != null) {
      //   print('FCM 디바이스 토큰: $token');
      // } else {
      //   print('FCM 디바이스 토큰을 가져오지 못 했습니다.');
      // }
    } catch (e) {
      log('FCM 디바이스 토큰 가져오기 오류: $e');
    }
  }
}