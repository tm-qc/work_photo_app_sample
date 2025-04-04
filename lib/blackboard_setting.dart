import 'package:flutter/material.dart';

// 黒板設定画面
class BlackboardSetting extends StatelessWidget {
  const BlackboardSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('黒板設定'),
      ),
      body: Center(
        child: Text('ここに黒板設定フォームを作っていく'),
      ),
    );
  }
}
