// =======================================
// 📊 デバッグ情報：現在の黒板のサイズ表示
// =======================================
import 'package:flutter/material.dart';

class BlackboardSizeDisplay extends StatelessWidget {
  final Size blackboardSize;
  final double? top;
  final double? right;

  const BlackboardSizeDisplay({
    super.key,
    required this.blackboardSize,
    this.top = 50,
    this.right = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '📏 ${blackboardSize.width.toInt()}×${blackboardSize.height.toInt()}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}