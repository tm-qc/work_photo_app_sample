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
            // Theme()ウィジェットによる個別のデザイン設定
            // Theme()ウィジェットは、そのchildプロパティに指定されたウィジェットツリーに対して、新しいテーマ設定を適用
            //
            // Theme() を使うのは「複数ボタンに共通で一括で適用したいとき」らしいが長くなるので後で例を記載します。
            //
            // 「1箇所だけ色を変えたい」なら style: ElevatedButton.styleFrom() で直接指定の方が簡潔
            ElevatedButton(
              // style: ElevatedButton.styleFrom()の例
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
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
