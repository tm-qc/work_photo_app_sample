
// 補足
// package:flutter/cupertino.dart は？
// iOSスタイルのUI（Cupertinoデザイン） を作るときに使います
// つまり、iPhone風の見た目の CupertinoButton や CupertinoNavigationBar などを使うとき専用
import 'package:flutter/material.dart';

class BlackboardLabel extends StatelessWidget {
  // 引数で受け取るための変数を定義
  final String text;
  final double width;

  // コンストラクタで引数に初期値など設定
  const BlackboardLabel({
    super.key,
    required this.text,
    this.width = 60,
  });

  @override
  Widget build(BuildContext context) {
    // Container：見た目を整えるための箱
    return Container(
      width: width,
      // padding指定だけだが、メソッド使い分けが必要みたいです
      // メソッド、引数名が長いし覚えにくい・・・
      //
      // EdgeInsets.all(8)：全方向に同じ余白	全部まとめて
      // EdgeInsets.symmetric(horizontal: 4, vertical: 6)：上下と左右で分けたいとき
      // EdgeInsets.only(left: 4, top: 2)：個別に設定したいとき
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white, width: 1),
          bottom: BorderSide(color: Colors.white, width: 1),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
