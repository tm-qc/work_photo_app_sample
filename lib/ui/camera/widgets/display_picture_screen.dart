import 'dart:io';
import 'package:flutter/material.dart';

class DisplayPictureScreen extends StatelessWidget {
  // 撮影された画像ファイルの保存パスを受け取る
  final String imagePath;
  // コンストラクタ。imagePathは必須
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('撮影した写真')),
      body: Column(
        children: [
          // 撮影画像を画面いっぱいに表示（縦に拡張）
          // Image.file(...) だけだと高さが確保されない可能性がある
          Expanded(
            child: Center(
              child: Image.file(File(imagePath)), // 撮影された画像を表示
            ),
          ),
          Padding(
            // EdgeInsets.all:上下左右すべてに同じサイズの余白をつけるための指定
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('保存する'),
              onPressed: () {
                // TODO: 保存機能は次ステップで追加（現在はキャッシュ保存済み）
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('保存はまだ未実装です')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
