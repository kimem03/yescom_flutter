import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

import '../api/server_service.dart';

class Button extends StatefulWidget {
  const Button({super.key});

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  final storage = const FlutterSecureStorage(); // FlutterSecureStorage를 storage로 저장
  String serverAddress = "";   // 서버 주소
  String phone = "";
  String id = "";
  String pw = "";
  String hexPw = "";
  String token = "";

  String result = "";
  String custId = "";
  bool guard = false;
  bool savedGuard = false;
  String mode = "";     // 요청 모드: 1 = 경계, 2 = 해제, 3 = 문열림

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  // 서버 주소 불러오기
  Future<String> _serverAddress() async {
    ServerService serverService = ServerService();
    serverAddress = await serverService.loadServerAddress();

    return serverAddress;
  }

  // 원격 요청 메서드
  Future<void> _remoteControl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    custId = prefs.getString('savedCustId') ?? '';
    guard = prefs.getBool('savedGuard') ?? false;

    serverAddress = await _serverAddress();
    phone = prefs.getString('savedPhone') ?? '';
    id = await storage.read(key: 'savedId') ?? '';
    pw = await storage.read(key: 'savedPw') ?? '';
    hexPw = utf8.encode(pw).map((e) => e.toRadixString(16).padRight(2, '0')).join();
    token = await storage.read(key: 'savedToken') ?? '';

    String control = "phone=$phone&id=$id&pw=$hexPw&method=remotecontrol&custid=$custId&mode=$mode";
    String controlUrl = serverAddress + control;

    try {
      // HTTP GET 요청 보내기
      final response = await http.get(Uri.parse(controlUrl));

      if (response.statusCode == 200) {
        log('전송 주소: $controlUrl');
        setState(() {
          if(mode == "1") {
            prefs.setBool('savedGuard', true);
          } else if (mode == "2") {
            prefs.setBool('savedGuard', false);
          }
        });
      }
    } catch (e) {
      log("전송 중 오류 발생: $e");
    }
  }

  // 정보 저장
  Future<void> _saveStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('savedGuard', guard);
    setState(() {
      savedGuard = guard;
    });
  }
  // 저장된 정보 불러오기
  Future<void> _loadStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedGuard = prefs.getBool('savedGuard') ?? false;
    });
  }

  // 토스트 메시지
  void showToast(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        gravity: ToastGravity.BOTTOM,   // 토스트 메시지 띄울 위치
        backgroundColor: Colors.grey,
        fontSize: 20,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT   // 토스트 메시지 띄우는 시간
    );
  }

  // 경계 버튼 클릭 다이얼로그
  Future<void> _showLockDialog(BuildContext context) {
    // if (guard) {
    //   // guard가 true일 때: 이미 경계 상태임
    //   return showDialog(
    //     barrierDismissible: false, // dialog 외부 탭 닫힘 방지
    //     context: context,
    //     builder: (BuildContext context) =>
    //         AlertDialog(
    //           title: const Text('알림'),
    //           content: const Text('이미 경계 상태입니다.'),
    //           actions: [
    //             TextButton(
    //               onPressed: () => Navigator.of(context).pop(),
    //               child: const Text('확인'),
    //             ),
    //           ],
    //         ),
    //   );
    // } else {
      return showDialog(
          barrierDismissible: false, // dialog 외부 탭 해도 닫히기 않게끔
          context: context,
          builder: (BuildContext context) =>
              AlertDialog(
                title: const Text('경계'),
                // 경계 상태에서 누르면 '이미 경계 상태입니다.' 뜨게끔
                content: const Text('경계 상태로 전환하시겠습니까?'),
                actions: [
                  TextButton(
                      onPressed: () =>
                      {
                        // 해제 상태에서 누르면 서버로 상태 변경 요청 메소드 전송 (RemoteControl)
                        setState(() {
                          mode = "1";
                          guard = true;
                          // Provider.of<StatusInfo>(context).saveStatusInfo(custId);
                      }),
                        _remoteControl(),
                        _saveStatus(),
                        showToast("경계 요청을 보냈습니다."),
                        Navigator.of(context).pop(),
                      },
                      child: const Text('네')
                  ),
                  // 아니오 버튼 클릭시, 추가 기능 없음
                  TextButton(
                      onPressed: () =>
                      {
                        Navigator.of(context).pop(),
                      },
                      child: const Text('아니오')
                  ),
                ],
              )
      );
    }
  // }
  // 경계 버튼 클릭 다이얼로그

  // 해제 버튼 클릭 다이얼로그
  Future<void> _showUnlockDialog(BuildContext context) {
    // if (!guard) {
    //   // guard가 false일 때: 이미 해제 상태임
    //   return showDialog(
    //     barrierDismissible: false, // dialog 외부 탭 닫힘 방지
    //     context: context,
    //     builder: (BuildContext context) =>
    //         AlertDialog(
    //           title: const Text('알림'),
    //           content: const Text('이미 해제 상태입니다.'),
    //           actions: [
    //             TextButton(
    //               onPressed: () => Navigator.of(context).pop(),
    //               child: const Text('확인'),
    //             ),
    //           ],
    //         ),
    //   );
    // } else {
      return showDialog(
          barrierDismissible: false, // dialog 외부 탭 해도 닫히기 않게끔
          context: context,
          builder: (BuildContext context) =>
              AlertDialog(
                title: const Text('해제'),
                content: const Text('해제 상태로 전환하시겠습니까?'),
                // 해제 상태에서 누르면 '이미 해제 상태입니다.' 뜨게끔
                actions: [
                  TextButton(
                      onPressed: () =>
                      {
                        // 경계 상태에서 누르면 서버로 상태 변경 요청 메소드 전송 (RemoteControl)
                        setState(() {
                          mode = "2";
                          guard = false;
                        }),
                        _remoteControl(),
                        _saveStatus(),
                        showToast("해제 요청을 보냈습니다."),
                        Navigator.of(context).pop(),
                      },
                      child: const Text('네')
                  ),
                  // 아니오 버튼 클릭시, 추가 기능 없음
                  TextButton(
                      onPressed: () =>
                      {
                        Navigator.of(context).pop(),
                      },
                      child: const Text('아니오')
                  ),
                ],
              )
      );
    }
  // }
  // 해제 버튼 클릭 다이얼로그

  // 문열림 버튼 클릭 다이얼로그
  Future<void> _showOpenDialog(BuildContext context) {
    return showDialog(
        barrierDismissible: false,  // dialog 외부 탭 해도 닫히기 않게끔
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('문열림'),
          content: const Text('문열림 상태로 전환하시겠습니까?'),
          actions: [
            TextButton(
                onPressed: () => {
                  // 서버로 상태 변경 요청 메소드 전송 (RemoteControl)
                  mode = "3",
                  _remoteControl(),
                  showToast("문열림 요청을 보냈습니다."),
                  Navigator.of(context).pop(),
                },
                child: const Text('네')
            ),
            // 아니오 버튼 클릭시, 추가 기능 없음
            TextButton(
                onPressed: () => {
                  Navigator.of(context).pop(),
                },
                child: const Text('아니오')
            ),
          ],
        )
    );
  }
  // 문열림 버튼 클릭 다이얼로그

  @override
  Widget build(BuildContext context) {
    // 경계 버튼
    var lock = MaterialButton(
      onPressed: (){ _showLockDialog(context); },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/slice/btn_3.png'),
          const Text('경계', style: TextStyle(fontSize: 18),),
        ],
      ),
    );

    // 해제 버튼
    var unlock = MaterialButton(
      onPressed: (){ _showUnlockDialog(context); },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/slice/btn_3.png'),
          const Text('해제', style: TextStyle(fontSize: 18),),
        ],
      ),
    );

    // 문열림 버튼
    var open = MaterialButton(
      onPressed: (){ _showOpenDialog(context); },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/slice/btn_3.png'),
          const Text('문열림', style: TextStyle(fontSize: 18),),
        ],
      ),
    );

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: lock),
          Expanded(child: unlock),
          Expanded(child: open),
        ],
      ),
    );
  }
}
