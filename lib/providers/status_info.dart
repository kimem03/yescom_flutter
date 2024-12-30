import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatusInfo with ChangeNotifier {
  // 초기 변수 선언
  String _custId = "";
  bool _inGuard = false;
  String _mode = "";

  // getter
  String get custId => _custId;
  bool get inGuard => _inGuard;
  String get mode => _mode;

  // SecureStorage, SharedPreferences 에 값 저장
  Future<void> loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _custId = prefs.getString('savedCustId') ?? '';
    _inGuard = prefs.getBool('savedGuard') ?? false;
    notifyListeners();  // 상태 변화 알리기
  }

  // 값 저장
  Future<void> saveStatusInfo(String custId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('savedCustId', custId);
    await prefs.setBool('savedGuard', inGuard);
    _custId = custId;
    _inGuard = inGuard;
    notifyListeners();  // 상태 변화 알리기
  }

  // 경계 상태를 토글하는 함수
  void toggleGuard() {
    _inGuard = !_inGuard;
    notifyListeners();  // 상태 변화 알리기
  }
}