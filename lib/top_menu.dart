import 'package:flutter/material.dart';
import 'blackboard_setting.dart';

class TopMenu extends StatelessWidget {
  const TopMenu({super.key});

  @override
  // Flutterはウィジェットを基本にレイアウト、デザインやしていくらしいが、
  // 何をどこにどういった法則で書くか？がバラバラ過ぎてつかめない・・
  // とりあえずこのコードに対しての補足をは書いていきます
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TOPメニュー')),
      // bodyに余白をつけるためにpaddingを設定
      // Paddingが不要な時は繰り上がってbody:GridView.countみたいになる
      body: Padding(
        // 上下左右に16pxの余白をつける。body: Paddingがあるのでpadding必須になる
        // ※pxは実際は「画面密度（デバイスのdpi）に合わせてFlutter側が自動調整したpx」
        padding: const EdgeInsets.all(16.0),
        // themeで共通のレイアウト設定
        // Columnのときは中にtheme書くが、GridViewの時は外に書くらしい
        child: Theme(
          // copyWithで取得した元のMD3テーマを設定したstyleに上書き
          data: Theme.of(context).copyWith(
            elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                  // MD3テンプレートのデフォが丸なので四角にする
                  borderRadius: BorderRadius.zero,
                ),
              //  最小サイズ を指定する
              //  GridView.count の場合、ボタンの幅は自動で2列分に分けられるから幅は 0 でOK
              //  ボタンの高さを最低100に固定する
              //  今回はchildAspectRatio:0.5で画面いっぱいにするので不要
              // minimumSize: Size(0, 100),
              textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),
          child: GridView.count(
            crossAxisCount: 2, // 2列
            crossAxisSpacing: 10, // 列間の隙間
            mainAxisSpacing: 10, // 行間の隙間
            // 幅：高さで要素の比率を決める
            // 今回は幅 : 高さ = 1:2 なので縦長長方形で画面いっぱいにするでちょうどよくなる
            // いろんな大きさのスマホがあるので、だいたいこれくらいでバランスよく調整してくれるイメージ
            //
            // 補足
            // childAspectRatio: 0.5：幅 : 高さ = 1:2 なので 縦長
            // childAspectRatio: 1.0：幅 : 高さ = 1:1 なので 正方形
            // childAspectRatio: 2.0：幅 : 高さ = 2:1 なので 横長
            // みたいになる。
            childAspectRatio:0.5,
            children: [
              // 1個目のボタン
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen, // 背景色
                ),
                onPressed: () {},
                child: Text('事業・現場\n情報ダウンロード', textAlign: TextAlign.center), // \nで改行
              ),
              // 2個目のボタン
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                // ボタンが押されたときに実行される処理
                onPressed: () {
                  // 黒板設定画面へ遷移（遷移先のTOPのAppBarに←の戻るボタンも自動でつきます）
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // constをつける理由は？
                      //
                      // const キーワードは、Flutter（Dart）において、コンパイル時に値が決定
                      // 実行時に変更されない定数（コンパイル時定数）を生成するために使用されます
                      // これにより、パフォーマンスとメモリ効率が向上します
                      //
                      // 読み込むクラスがStatelessWidgetかつ状態変化を持っていないウィジェットであることがconstをつけれる条件
                      // 仮に後で状態変化を持った場合はエラーになるのでconstを外せばいい
                      builder: (context) => const BlackboardSetting(),
                    ),
                  );
                },
                child: Text('黒板設定'),
              ),
              // 3個目のボタン
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                onPressed: () {},
                child: Text('写真撮影'),
              ),
              // 4個目のボタン
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: () {},
                child: Text('写真アップ\nロード', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
