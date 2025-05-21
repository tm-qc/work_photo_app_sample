import 'package:flutter/material.dart';

class BlackboardValue extends StatelessWidget {
  final String text;
  final int flex;

  const BlackboardValue({
    super.key,
    this.text = "未設定",
    // 必要な場合に横幅の比率を調整できる
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    // Expanded：Containerで使ってない幅＝RowやColumn内で、残りのスペースを自動で広がるように使う指示するメソッド
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white, width: 1),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}
