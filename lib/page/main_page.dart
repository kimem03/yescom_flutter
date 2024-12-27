import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/server_service.dart';
import '../widget/appbar.dart';
import '../page/login_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final storage = const FlutterSecureStorage(); // FlutterSecureStorage를 storage로 저장
  String serverAddress = "";   // 서버 주소
  String phone = "";
  String id = "";
  String pw = "";

  List<String> custIdList = [];       // 관리 번호 배열
  List<String> hexCustNameList = [];  // 관리명 (hexadecimal) 배열
  List<String> custNameList = [];     // 관리명 (decode) 배열
  List<bool> inGuardList = [];        // 경계/해제 배열

  String custId = "";       // 관리 번호
  String hexCustName = "";  // 관리명 (hexadecimal)
  String custName = "";     // 관리명 (decode)
  bool inGuard = false;      // 경계 = true, 해제 = false

  String? dropdownValue = "";  // 드롭다운 기본 요소

  @override
  void initState(){
    super.initState();
    _loadStatusInfo();
    _loadData();
  }

  // 데이터를 불러오는 함수
  Future<void> _loadData() async {
    phone = await _loadPhone() ?? '';
    id = await _loadId() ?? '';
    pw = await _loadPw() ?? '';

    // 서버 주소 불러오기
    String serverAddress = await _serverAddress();

    // 모든 값을 로드한 후, 상태 갱신
    setState(() {
      phone = phone;
      id = id;
      pw = pw;
      this.serverAddress = serverAddress;
    });
  }

  // 전화번호 불러오기
  Future<String?> _loadPhone() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    phone = prefs.getString('savedPhone') ?? '';
    return phone;
  }

  // id 불러오기
  Future<String?> _loadId() async {
    id = await storage.read(key: 'savedId') ?? '';
    return id;
  }

  // pw 불러오기
  Future<String?> _loadPw() async {
    pw = await storage.read(key: 'savedPw') ?? '';
    return pw;
  }

  // 서버 주소 불러오기
  Future<String> _serverAddress() async {
    ServerService serverService = ServerService();
    serverAddress = await serverService.loadServerAddress();

    return serverAddress;
  }

  // hexadecimal decoding
  String decodeHexToKorean(String hex){
    // hex 값을 byte로 변환
    List<int> bytes = [];
    for(int i = 0; i < hex.length; i += 2) {
      String byteString = hex.substring(i, i+2);      // 두 자리씩 자르기
      bytes.add(int.parse(byteString, radix: 16));    // 16진수 -> 10진수 변환
    }

    // 한글로 변환 UTF-8
    String decodedString = utf8.decode(bytes);
    return decodedString;
  }

  // 현재 상태 불러오기
  Future<void> _loadStatusInfo() async {
    // 서버 주소
    serverAddress = await _serverAddress();

    // 정보 url
    String status = LoginUtils.sendStatus(phone, id, pw);
    String statusUrl = serverAddress + status;

    try {
      final response = await http.get(Uri.parse(statusUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        // 배열 길이 만큼 반복
        for (int i = 0; i < jsonData['Data'].length; i++) {
          // mounted가 true일 때만 setState 호출
          if (mounted) {
            setState(() {
              custIdList.add(jsonData['Data'][i]['CustID']); // 관리 번호 추가
              hexCustNameList.add(jsonData['Data'][i]['CustName']); // 관리명 (Hex) 추가
              inGuardList.add(jsonData['Data'][i]['InGuard']); // 경계 상태 추가
              custNameList.add(decodeHexToKorean(hexCustNameList[i]));
            });
          }
        }
      }
    } catch (e) {
      log("오류 발생 $e");
    }
  }
  // 현재 상태 불러오기

  // 드롭다운 기본 값 정의
  @override
  void setState(VoidCallback fn) {
    dropdownValue = custNameList.isNotEmpty ? custNameList[0] : '';
  }

  // 드롭 다운 요소
  Widget _dropdown() {
    // custNameList가 비어있는지 확인 후 기본값 설정
    if (custNameList.isEmpty) {
      dropdownValue = '';   // 공백 출력
    } else {
      dropdownValue = custNameList.first;
    }

    return DropdownButton(
      value: dropdownValue,
      items: custNameList.map<DropdownMenuItem<String>>((String value){
        return DropdownMenuItem<String>(
            value: value,
            child: Text(value)
        );
      }).toList()
      , onChanged: (String? value) {
        setState(() {
          dropdownValue = value!;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    Image resetImg = Image.asset('assets/slice/_Reset.png');  // 해제
    Image setImg = Image.asset('assets/slice/_Set.png');      // 경계

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

    return MaterialApp(
      home: Scaffold(
        body: Column(
        children: [
          Expanded(child: top),
          Expanded(child: Text('phone: $phone \n id: $id \n pw: $pw \n server: $serverAddress'),),
        ],
        ),
      ),
    );
  }

}
