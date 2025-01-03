import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatusInfo with ChangeNotifier {
  // 초기 변수 선언
  String _custId = "";
  String _custName = "";
  bool _inGuard = false;
  String _mode = "";

  // getter
  String get custId => _custId;
  String get custName => _custName;
  bool get inGuard => _inGuard;
  String get mode => _mode;

  // 상태 값을 변경할 수 있는 함수
  void setInGuard(bool status) {
    _inGuard = status;
    notifyListeners(); // 상태가 변경되면 리스너들에게 알림
  }

  // SecureStorage, SharedPreferences 에 값 저장
  Future<void> loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _custId = prefs.getString('savedCustId') ?? '';
    _custName = prefs.getString('savedCustName') ?? '';
    _inGuard = prefs.getBool('savedGuard') ?? false;
    _mode = prefs.getString('savedMode') ?? '';
    notifyListeners();  // 상태 변화 알리기
  }

  // 값 저장
  Future<void> saveStatusInfo(String custId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('savedCustId', custId);
    await prefs.setString('savedCustName', custName);
    await prefs.setBool('savedGuard', inGuard);
    await prefs.setString('savedMode', mode);
    _custId = custId;
    _custName = custName;
    _inGuard = inGuard;
    _mode = mode;
    notifyListeners();  // 상태 변화 알리기
  }
}