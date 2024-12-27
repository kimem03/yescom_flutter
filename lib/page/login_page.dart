import 'dart:convert';  // JSON 인코딩/디코딩에 필요함
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:yescom_front/api/server_service.dart';

import 'home_page.dart';
import '../providers/user_info.dart';   // 전역 변수 import

// 상태 정보 전송 함수
class LoginUtils {
  static String sendStatus(String phone, String id, String pw) {
    String hexPw = utf8.encode(pw).map((e) => e.toRadixString(16).padRight(2, '0')).join();
    return "phone=$phone&id=$id&pw=$hexPw&method=currentstatus";
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // id pw 저장을 위한 storage
  final storage = const FlutterSecureStorage(); // FlutterSecureStorage를 storage로 저장

  bool _idChecked = false;  // id 저장 체크 (기본: false)
  bool _pwChecked = false;  // pw 저장 체크 (기본: false)
  bool _isAuth = false;     // 인증 여부 (기본: false)

  String id = "";     // 사용자 id
  String pw = "";     // 사용자 pw
  String hexPw = "";  // hexadecimal pw
  String phone = "";  // 사용자 전화번호

  String userAuthNo = ""; // 사용자가 입력한 인증 번호
  String serverAuthNo = ""; // 서버에서 전송한 인증 번호

  String dKind = "";  // 단말기 종류 (1: Android, 2: IOS)
  String? dToken = "";  // 단말기 토큰
  String hexToken = ""; // hexadecimal token

  String savedPhone = "";   // 인증 완료 후 저장된 전화번호
  String savedId = "";      // id 저장
  String savedPw = "";      // pw 저장

  String serverAddress = "";  // 서버 주소
  String result = "";    // json 결과값

  bool isAuthNoEnable = false;  // 인증번호 활성화 여부 (기본: false)
  bool isButtonEnable = false;  // 버튼 활성화 여부 (기본: false)
  bool isPhoneEnable = true;    // 전화번호 입력란 활성화 여부 (기본: true)

  // 전화번호 컨트롤러
  final TextEditingController _phoneController = TextEditingController();
  // id 컨트롤러
  final TextEditingController _idController = TextEditingController();
  // pw 컨트롤러
  final TextEditingController _pwController = TextEditingController();
  // 인증 번호 컨트롤러
  final TextEditingController _authController = TextEditingController();

  // 초기화
  @override
  void initState(){
    super.initState();
    _loadAuth();
    _initState();

    // 입력한 변경을 감지하여 버튼 상태 업데이트
    _phoneController.addListener((){
      setState(() {
        isButtonEnable = _phoneController.text.trim().isNotEmpty;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_){
      _loadId();
      _loadPw();
    });
  }

  @override
  void dispose(){
    _phoneController.dispose();
    _authController.dispose();
    super.dispose();
  }

  // 저장된 체크박스 상태와 id pw 불러오기
  Future<void> _initState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _idChecked = prefs.getBool('_idChecked') ?? false;
      _pwChecked = prefs.getBool('_pwChecked') ?? false;
    });

    if (_idChecked) {await _loadId();}
    if (_pwChecked) {await _loadPw();}
  }

  // id 저장
  Future<void> _saveId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('_idChecked', _idChecked);
    if (_idChecked) {
      await storage.write(key: 'savedId', value: _idController.text.trim());
    } else {
      await _clearId(); // 체크 해제 시 ID 삭제
    }
  }

  // PW 저장
  Future<void> _savePw() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('_pwChecked', _pwChecked);

    if (_pwChecked) {
      await storage.write(key: 'savedPw', value: _pwController.text.trim());
    } else {
      await _clearPw(); // 체크 해제 시 PW 삭제
    }
  }

  // 저장된 ID 불러오기
  Future<void> _loadId() async {
    String? savedId = await storage.read(key: 'savedId');
    setState(() {
      _idController.text = savedId ?? '';
    });
  }

  // 저장된 PW 불러오기
  Future<void> _loadPw() async {
    String? savedPw = await storage.read(key: 'savedPw');
    setState(() {
      _pwController.text = savedPw ?? '';
    });
  }

  // ID 초기화
  Future<void> _clearId() async {
    await storage.delete(key: 'savedId');
    setState(() {
      _idController.clear();
    });
  }

  // PW 초기화
  Future<void> _clearPw() async {
    await storage.delete(key: 'savedPw');
    setState(() {
      _pwController.clear();
    });
  }

  // 인증 여부 확인
  Future<void> _checkAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(!_isAuth){
      prefs.setString('savedPhone', phone);
      prefs.setBool('_isAuth', true);
    }

    setState(() {
      _isAuth = true;
      savedPhone = phone;
    });
  }
  // 인증 여부 불러오기
  Future<void> _loadAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAuth = prefs.getBool('_isAuth') ?? false;
      savedPhone = prefs.getString('savedPhone') ?? '';
    });
  }

  // 서버 주소 불러오기
  Future<String> _serverAddress() async {
    ServerService serverService = ServerService();
    serverAddress = await serverService.loadServerAddress();

    return serverAddress;
  }

  // 로그인 정보 전송
  Future<void> _sendLoginInfo() async {
    // Ensure savedPhone is loaded
    if (savedPhone.isEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      savedPhone = prefs.getString('savedPhone') ?? '';
    }
    // if (Provider.of<UserInfo>(context, listen: false).phone.isEmpty) {
    //   SharedPreferences prefs = await SharedPreferences.getInstance();
    //   savedPhone = prefs.getString('savedPhone') ?? '';
    // }

    // 서버 주소 받아오기
    // Future<String>이기 때문에 비동기로 받아야 함 (await)
    serverAddress = await _serverAddress();

    id = _idController.text.trim();
    pw = _pwController.text.trim();
    hexPw = utf8.encode(pw).map((e) => e.toRadixString(16).padRight(2, '0')).join();

    String authLogin = "phone=$savedPhone&id=$id&pw=$hexPw&method=login";
    String loginUrl = serverAddress + authLogin;

    if (id.isNotEmpty && pw.isNotEmpty) {
      try {
        // http get 요청 전송
        final response = await http.get(Uri.parse(loginUrl));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResult = jsonDecode(response.body);
          setState(() {
            result = jsonResult['Result'];
          });

          if(result == 'OK'){
          } else {
            _showDialog("로그인 실패", "아이디와 비밀번호를 확인해주세요.");
          }
        }
      } catch (e) {
        log("데이터 전송 중 오류 발생: $e");
      }
    } else if (id.isEmpty || pw.isEmpty) {
      _showDialog("로그인 실패", "아이디와 비밀번호를 입력해주세요.");
    }
  }
  // 로그인 정보 전송

  // 단말기 정보 전송
  Future<void> _sendMobileInfo() async {
    // Ensure savedPhone is loaded
    if (savedPhone.isEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      savedPhone = prefs.getString('savedPhone') ?? '';
    }

    // 서버 주소
    serverAddress = await _serverAddress();

    // 단말기 토큰 불러오기
    dToken = await FirebaseMessaging.instance.getToken();
    hexToken =utf8.encode(dToken!).map((e) => e.toRadixString(16).padLeft(2, '0')).join();

    // 단말기 정보 (android/ios)
    if (Platform.isAndroid) {
      dKind = "1";
    } else if (Platform.isIOS) {
      dKind = "2";
    }

    String mobile = "phone=$savedPhone&id=$id&pw=$hexPw&method=mobileinfo&dkind=$dKind&dtoken=$hexToken";
    String mobileUrl = serverAddress + mobile;

    if (id.isNotEmpty && pw.isNotEmpty) {
      try {
        // HTTP GET 요청 보내기
        final response = await http.get(Uri.parse(mobileUrl));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResult = jsonDecode(response.body);
          setState(() {
            result = jsonResult['Result'];
          });

          if(result == 'OK'){
          }
        }
      } catch (e) {
        log("단말기 정보 전송 중 오류 발생: $e");
      }
    }
  }
  // 단말기 정보 전송

  // 로그인 버튼 클릭 핸들러 (로그인, 모바일 정보 통합)
  Future<void> _handleLoginBtn() async {
    // Ensure savedPhone is loaded
    if (savedPhone.isEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      savedPhone = prefs.getString('savedPhone') ?? '';
    }

    serverAddress = await _serverAddress();
    await _sendLoginInfo();   // 로그인 정보 전송
    await _sendMobileInfo();  // 단말기 정보 전송

    if (id.isNotEmpty && pw.isNotEmpty) {
      // 로그인 시 현재 상태 요청
      String state = "phone=$savedPhone&id=$id&pw=$hexPw&method=currentstatus";
      String stateUrl = serverAddress + state;

      try {
        // HTTP GET 요청 보내기
        final response = await http.get(Uri.parse(stateUrl));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResult = jsonDecode(response.body);
          setState(() {
            result = jsonResult['Result'];
          });

          if (result == 'OK') {
            // 로그인 성공 시
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );

            _checkAuth();
            // print(stateUrl);
          }
        }
      } catch (e) {
        log("오류 발생: $e");
      }
    }
  }
  // 로그인 버튼 핸들러

  // 인증 번호 받기 핸들러
  Future<void> _handleAuthNoBtn() async {
    serverAddress = await _serverAddress();

    phone = _phoneController.text.trim();
    String authPhone = "phone=$phone&id=&pw=&method=auth";
    String authUrl = serverAddress + authPhone;

    try {
      // HTTP GET 요청 보내기
      final response = await http.get(Uri.parse(authUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        setState(() {
          serverAuthNo = jsonData['Data']['AuthNo'];
          isAuthNoEnable = true; // 인증번호 입력 창 표시
        });
      }
    } catch (e) {
      log("데이터 전송 중 오류 발생: $e");
    }
  }
  // 인증 번호 받기 핸들러

  // 인증 번호 확인 핸들러
  Future<void> _handleAuthCheckBtn() async {
    userAuthNo = _authController.text.trim();

    if (userAuthNo == serverAuthNo) {
      _showDialog("인증 성공", "인증 번호가 일치합니다.");
    } else {
      _showDialog("인증 실패", "인증 번호가 일치하지 않습니다.");
    }
  }

  // 다이얼로그 출력 구문
  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                if (title == "인증 성공") {
                  // 인증 성공 시 입력란과 버튼 비활성화
                  setState(() {
                    isAuthNoEnable = false;
                    isButtonEnable = false;
                    isPhoneEnable = false;
                  });
                }
                Navigator.of(context).pop(); // Dialog 닫기
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }
  // 다이얼로그 출력 구문

  @override
  Widget build(BuildContext context) {
    // UserInfo를 Provider를 통해 접근
    var userInfo = Provider.of<UserInfo>(context);
    final Size size = MediaQuery.of(context).size;

    // 입력란
    var input = GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus(); // 화면 터치 시 키보드 닫힘
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.only(top: 30)),
            Form(
              child: Theme(
                  data: ThemeData(
                    primaryColor: Colors.grey,
                    inputDecorationTheme: const InputDecorationTheme(
                      labelStyle: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        // id 입력란
                        TextField(
                          controller: _idController,
                          decoration: const InputDecoration(
                            labelText: "ID를 입력해주세요."
                          ),
                          keyboardType: TextInputType.text,
                          onChanged: (value) {
                            if (_idChecked) {
                              _saveId();
                              savedId = _idController.text.trim();
                            }
                          },

                        ),

                        // pw 입력란
                        TextField(
                          controller: _pwController,
                          decoration: const InputDecoration(
                            labelText: "비밀번호를 입력해주세요."
                          ),
                          keyboardType: TextInputType.text,
                          obscureText: true,  // 내용 감추기
                          onChanged: (value) {
                            if (_pwChecked) {
                              _savePw();
                            }
                          },
                        ),

                        // 전화번호 입력란 (최초 1회만)
                        _isAuth
                        ? const SizedBox(height: 0,)
                        : TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                              labelText: "전화번호를 입력해주세요."
                          ),
                          keyboardType: TextInputType.phone,
                          enabled: isPhoneEnable,
                        ),
                        // const SizedBox(height: 30,),

                        // 인증 번호 입력란 (최초 1회만)
                        _isAuth
                        ? const SizedBox(height: 0,)
                        : TextField(
                          controller: _authController,
                          decoration: const InputDecoration(
                              labelText: "인증 번호를 입력해주세요."
                          ),
                          keyboardType: TextInputType.number,
                          enabled: isAuthNoEnable,
                        ),
                        const SizedBox(height: 30,),
                        // const Text('\n'),

                        // 인증하기 버튼 (최초 1회만)
                        _isAuth
                        ? const SizedBox(height: 0,)
                        : SizedBox(
                          height: size.height * 0.06,
                          width: size.width * 0.9,
                          child: MaterialButton(
                            onPressed: isAuthNoEnable ? _handleAuthCheckBtn : null,
                            color: const Color.fromRGBO(0, 93, 171, 1), // 활성화 시 색상
                            disabledColor: const Color.fromRGBO(204, 204, 204, 1),  // 비활성화 시 색상
                            child: const Text('인증하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const Text('\n'),

                        // 인증번호 받기 버튼 (최초 1회만)
                        _isAuth
                        ? const SizedBox(height: 0,)
                        : SizedBox(
                          height: size.height * 0.06,
                          width: size.width * 0.9,
                          child: MaterialButton(
                            onPressed: isButtonEnable ? _handleAuthNoBtn : null,
                            color: const Color.fromRGBO(0, 93, 171, 1), // 활성화 시 색상
                            disabledColor: const Color.fromRGBO(204, 204, 204, 1),  // 비활성화 시 색상
                            child: const Text('인증번호 받기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const Text('\n'),

                        // 로그인 버튼
                        SizedBox(
                          height: size.height * 0.06,
                          width: size.width * 0.9,
                          child: MaterialButton(
                            onPressed: _handleLoginBtn,
                            color: const Color.fromRGBO(0, 93, 171, 1),
                            child: const Text('로그인',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),

                        Row(
                          children: [
                            Checkbox(
                              value: _idChecked,
                              onChanged: (bool? value) async {
                                setState(() {
                                  _idChecked = value ?? false;
                                });
                                await _saveId();
                                if(!_idChecked) _clearId();
                              },
                              activeColor: const Color.fromRGBO(0, 93, 171, 1),
                            ),
                            const Text('ID 저장하기', style: TextStyle(fontSize: 18),),

                            Checkbox(value: _pwChecked,
                              onChanged: (bool? value) async {
                                setState(() {
                                  _pwChecked = value ?? false;
                                });
                                await _savePw();
                                if(!_pwChecked) _clearPw();
                              },
                              activeColor: const Color.fromRGBO(0, 93, 171, 1),
                            ),
                            const Text('PW 저장하기', style: TextStyle(fontSize: 18),),
                          ],
                        )
                      ],
                    ),
                  ),
              ),
            ),
          ],
        ),
      ),
    );

    return MaterialApp(
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Scaffold(
            body: Container(
              margin: const EdgeInsets.only(top: 50),
              alignment: Alignment.center,
              child: Image.asset('assets/slice/login_logo.png'),
            ),
          ),
        ),
        body: input,
      ),
    );
  }
}
