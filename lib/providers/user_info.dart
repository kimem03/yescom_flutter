import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const storage = FlutterSecureStorage();

class UserInfo with ChangeNotifier {
  // 초기 변수 선언
  String _id = '';
  String _pw = '';
  String _phone = '';
  String _serverAddress = '';

  // getter
  String get id => _id;
  String get pw => _pw;
  String get phone => _phone;
  String get serverAddress => _serverAddress;

  // SecureStorage, SharedPreferences 에 값 저장
  Future<void> loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _id = await storage.read(key: 'savedId') ?? '';
    _pw = await storage.read(key: 'savedPw') ?? '';
    _phone = prefs.getString('savedPhone') ?? '';
    notifyListeners();  // 상태 변화 알리기
  }

  // 값 저장
  Future<void> saveUserInfo(String id, String pw, String phone) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await storage.write(key: 'savedId', value: id);
    await storage.write(key: 'savedPw', value: pw);
    await prefs.setString('savedPhone', phone);
    _id = id;
    _pw = pw;
    _phone = phone;
    notifyListeners();  // 상태 변화 알리기
  }
}