import 'package:flutter/material.dart';

class BlackboardValue extends StatelessWidget {
  final String text;
  final int flex;
  final bool showRightBorder;

  const BlackboardValue({
    super.key,
    this.text = "",
    // 必要な場合に横幅の比率を調整できる
    this.flex = 1,
    // 右側の線が二重になる部分があるので制御用
    this.showRightBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    // Expanded：Containerで使ってない幅＝RowやColumn内で、残りのスペースを自動で広がるように使う指示するメソッド
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
        decoration: BoxDecoration(
          border: Border(
            right: showRightBorder
                ? const BorderSide(color: Colors.white, width: 1)
                : BorderSide.none,
            bottom: const BorderSide(color: Colors.white, width: 1),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          overflow: TextOverflow.ellipsis, // 文字数が多すぎる場合に「…」で表示を切れる
          maxLines: 1,                     // 複数行にしない
        ),
      ),
    );
  }
}
