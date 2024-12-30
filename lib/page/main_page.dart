import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cp949_codec/cp949_codec.dart';
import 'package:yescom_front/widget/button.dart';

import '../api/server_service.dart';
import '../widget/appbar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final PageStorageKey<String> dropdownKey = PageStorageKey<String>('dropdown');
  final storage = const FlutterSecureStorage(); // FlutterSecureStorage를 storage로 저장
  String serverAddress = "";   // 서버 주소
  String phone = "";
  String id = "";
  String pw = "";
  String hexPw = "";

  List<String> custIdList = [];       // 관리 번호 배열
  List<String> hexCustNameList = [];  // 관리명 (hexadecimal) 배열
  List<String> custNameList = [];     // 관리명 (decode) 배열
  List<bool> inGuardList = [];        // 경계/해제 배열

  String custId = "";       // 관리 번호
  String hexCustName = "";  // 관리명 (hexadecimal)
  String custName = "";     // 관리명 (decode)
  bool inGuard = false;      // 경계 = true, 해제 = false
  int len = 0;
  String savedCustId = "";
  bool savedGuard = false;

  String? dropdownValue = "";  // 드롭다운 기본 요소

  // 경계/해제 이미지 상태를 변경하는 메서드
  void toggleGuard() {
    setState(() {
      savedGuard = !savedGuard;  // savedGuard 값을 반전시켜 경계/해제 상태를 변경
    });
  }

  @override
  void initState(){
    super.initState();
    _loadStatusInfo();
    _loadStatus();

    if (custNameList.isNotEmpty) {
      dropdownValue = custNameList.first;
      custId = custIdList.first;
      inGuard = inGuardList.first;
    } else {
      dropdownValue = ''; // 기본값을 설정
    }
  }

  // 서버 주소 불러오기
  Future<String> _serverAddress() async {
    ServerService serverService = ServerService();
    serverAddress = await serverService.loadServerAddress();

    return serverAddress;
  }

  // 현재 상태 불러오기
  Future<void> _loadStatusInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    serverAddress = await _serverAddress();
    phone = prefs.getString('savedPhone') ?? '';
    id = await storage.read(key: 'savedId') ?? '';
    pw = await storage.read(key: 'savedPw') ?? '';
    hexPw = utf8.encode(pw).map((e) => e.toRadixString(16).padRight(2, '0')).join();

    // 정보 url
    String state = "phone=$phone&id=$id&pw=$hexPw&method=currentstatus";
    String stateUrl = serverAddress + state;

    try {
      final response = await http.get(Uri.parse(stateUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        len = jsonData['Data'].length;
        log("전송 url: $stateUrl");
        log("$jsonData");

        if (jsonData['Result'] == 'OK') {
          jsonData['Data'].forEach((value) {
            custIdList.add(value['CustID']);
            hexCustNameList.add(value['CustName']);
            inGuardList.add(value['InGuard']);
          });
          for (int i = 0; i < len; i++) {
            custNameList.add(decodeHexToKorean(hexCustNameList[i]));
          }
        }
      } else {
        log("전송 실패: $stateUrl");
      }
    } catch (e) {
      log("오류 발생 $e");
    }
  }
  // 현재 상태 불러오기

  // hexadecimal decoding
  String decodeHexToKorean(String hex){
    // hex 값인지 확인 (16진수 형식 검증)
    if (hex.isEmpty || hex.length % 2 != 0) {
      log("Invalid hex string: $hex");
      return "Invalid Data";
    }

    // hex 값을 byte로 변환
    List<int> bytes = [];
    for(int i = 0; i < hex.length; i += 2) {
      String byteString = hex.substring(i, i+2);      // 두 자리씩 자르기
      bytes.add(int.parse(byteString, radix: 16));    // 16진수 -> 10진수 변환
    }

    // cp949 디코드
    String decodedCp949 = cp949.decode(bytes);

    // utf-8 인코드
    List<int> encodedUtf = utf8.encode(decodedCp949);

    // utf-8로 변환된 문자열 다시 디코드
    String decodedString = utf8.decode(encodedUtf);

    // 한글로 변환 UTF-8
    return decodedString;
  }

  // 드롭 다운 요소
  Widget _dropdown() {
    if (custNameList.isNotEmpty) {
      dropdownValue = custNameList.first;
      custId = custIdList.first;
      inGuard = inGuardList.first;
    }

    return DropdownButton<String>(
      key: dropdownKey,
      value: dropdownValue,
      items: custNameList.map<DropdownMenuItem<String>>((String value){
        return DropdownMenuItem<String>(
            value: value,
            child: Text(value)
        );
      }).toList()
      , onChanged: (String? value) {
        if (value != null) {
          setState(() {
            dropdownValue = value;
            // 선택된 값에 따라 `custId`와 `inGuard` 업데이트
            int index = custNameList.indexOf(value);
            custId = custIdList[index];
            inGuard = inGuardList[index];
            _saveStatus();
            log('저장된 상태: $savedGuard');
            log('저장된 id: $savedCustId');
          });
        }
      },
    );
  }
  // 드롭 다운 요소

  // 정보 저장
  Future<void> _saveStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('savedCustId', custId);
    // prefs.setBool('savedGuard', inGuard);
    setState(() {
      savedCustId = custId;
      // savedGuard = inGuard;
    });
  }
  // 저장된 정보 불러오기
  Future<void> _loadStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedCustId = prefs.getString('savedCustId') ?? '';
      savedGuard = prefs.getBool('savedGuard') ?? false;
    });
  }

  // 해제
  Widget _isUnlock() {
    return const Center(
      child: Text.rich(
        TextSpan(
          text: "현재 ",
          children: [
            TextSpan(
              text: "해제 ",
              style: TextStyle(color: Colors.green),
              children: [
                TextSpan(
                    text: "상태 입니다.",
                    style: TextStyle(color: Colors.black)
                ),
              ],
            ),
          ],
        ),
        style: TextStyle(fontSize: 25),
      ),
    );
  }

  // 경계
  Widget _isLock() {
    return const Center(
      child: Text.rich(
        TextSpan(
          text: "현재 ",
          children: [
            TextSpan(
              text: "경계 ",
              style: TextStyle(color: Color.fromRGBO(235, 11, 0, 1)),
              children: [
                TextSpan(
                    text: "상태 입니다.",
                    style: TextStyle(color: Colors.black)
                ),
              ],
            ),
          ],
        ),
        style: TextStyle(fontSize: 25),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    Image resetImg = Image.asset('assets/slice/_Reset.png', width: size.width * 0.5,);  // 해제
    Image setImg = Image.asset('assets/slice/_Set.png', width: size.width * 0.5,);      // 경계

    // 상단 바, 드롭다운
    var top = SafeArea(
        child: Scaffold(
          appBar: const PreferredSize(
              preferredSize: Size.fromHeight(70),
              child: Appbar(),
          ),
          body: SafeArea(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset('assets/slice/table_head_bg.png', width: size.width * 0.9,),
                    _dropdown(),
                  ],
                ),
              )
          ),
        ),
    );

    // 경계/해제 이미지
    var lockUnlock = Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/slice/bg_lock.png',
            height: size.height * 0.9,
            width: size.width,
            fit: BoxFit.contain,),
          if (savedGuard) ...[
            Positioned(
              top: 10,
              child: _isLock(),
            ),
            Positioned(
              bottom: 0,
              child: setImg,
            ),
          ] else ...[
            Positioned(
              top: 10,
              child: _isUnlock(),
            ),
            Positioned(
              bottom: 0,
              child: resetImg,
            ),
          ]
        ],
      ),
    );

    // 버튼
    var btn = Button();

    // 배너
    var banner = Container(
      margin: EdgeInsets.fromLTRB(0, size.height*0.06, 0, 0),
      child: Scaffold(
        body: Image.asset('assets/slice/banner.png',
          fit: BoxFit.fitWidth,
          width: double.infinity,),
      ),
    );

    return MaterialApp(
      home: Scaffold(
        body: Column(
        children: [
          Expanded(child: top),
          Expanded(child: lockUnlock),
          Expanded(child: btn),
          Expanded(child: banner),
        ],
        ),
      ),
    );
  }

}
