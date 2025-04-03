import 'package:flutter/material.dart';

// TOPメニュー画面
class TopMenu extends StatelessWidget {
  const TopMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TOPメニュー')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {}, // 未実装
              child: Text('事業・現場情報ダウンロード'),
            ),
            ElevatedButton(
              onPressed: () {}, // 未実装
              child: Text('写真撮影'),
            ),
            ElevatedButton(
              onPressed: () {
                // 黒板設定画面へ遷移
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => BlackboardSetting()),
                // );
              },
              child: Text('黒板設定'),
            ),
            ElevatedButton(
              onPressed: () {}, // 未実装
              child: Text('写真アップロード'),
            ),
          ],
        ),
      ),
    );
  }
}
