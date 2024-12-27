import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  const Button({super.key});

  // 경계 버튼 클릭 다이얼로그
  Future<void> _showLockDialog(BuildContext context) {
    return showDialog(
      barrierDismissible: false,  // dialog 외부 탭 해도 닫히기 않게끔
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('경계'),
          content: const Text('경계 상태로 전환하시겠습니까?'),  // 경계 상태에서 누르면 '이미 경계 상태입니다.' 뜨게끔
          actions: [
            TextButton(
                onPressed: () => {
                  // 서버 전송 코드 짜야함
                  // 해제 상태에서 누르면 서버로 상태 변경 요청 메소드 전송 (RemoteControl)
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
  // 경계 버튼 클릭 다이얼로그

  // 해제 버튼 클릭 다이얼로그
  Future<void> _showUnlockDialog(BuildContext context) {
    return showDialog(
        barrierDismissible: false,  // dialog 외부 탭 해도 닫히기 않게끔
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('해제'),
          content: const Text('해제 상태로 전환하시겠습니까?'),  // 해제 상태에서 누르면 '이미 해제 상태입니다.' 뜨게끔
          actions: [
            TextButton(
                onPressed: () => {
                  // 서버 전송 코드 짜야함
                  // 경계 상태에서 누르면 서버로 상태 변경 요청 메소드 전송 (RemoteControl)
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
                  // 서버 전송 코드 짜야함
                  // 서버로 상태 변경 요청 메소드 전송 (RemoteControl)
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
    final Size size = MediaQuery.of(context).size;

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
