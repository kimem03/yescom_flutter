import 'dart:convert';

import 'package:flutter/services.dart';

class ServerService {
  Future<String> loadServerAddress() async {
    try {
      // JSON 파일 불러오기
      String jsonString = await rootBundle.loadString('assets/env/data.json');

      // JSON 문자열을 Map으로 변환
      final jsonData = jsonDecode(jsonString);

      // "server" 키의 값 반환
      return jsonData['server'];
    } catch (e) {
      print("Error loading server address: $e");
      return "";
    }
  }
}