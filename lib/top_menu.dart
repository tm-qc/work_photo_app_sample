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
            // 「1箇所だけ色を変えたい」なら style: ElevatedButton.styleFrom() で直接指定の方が簡潔
            ElevatedButton(
              // style: ElevatedButton.styleFrom()の例
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {}, // 未実装
              child: Text('事業・現場情報ダウンロード'),
            ),
            Theme(
              // Theme()ウィジェットによる個別のデザイン設定例1
              //
              // ウィジェット内でテーマ情報を Theme.of(context) で取得できる
              // copyWithで設定した色で上書き
              //
              // 注意
              // Theme.of() を使うときは context の位置に注意。
              // build()内ですぐに Theme.of() を読むと取れない場合がある
              // その場合は、1個下に Builder() を入れる
              data: Theme.of(context).copyWith(
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // ← 緑色に変更
                  ),
                ),
              ),
              child: ElevatedButton(
                onPressed: () {}, // 未実装
                child: Text('写真撮影'),
              ),
              // なお一括設定できるとあるが、単純なchild追加では複数設定できないらしい
              // わかりづらいが一括設定の方法は別途記載する。
              // ↓これはエラーNG
              // child: ElevatedButton(
              //   onPressed: () {}, // 未実装
              //   child: Text('写真撮影2'),
              // ),
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
