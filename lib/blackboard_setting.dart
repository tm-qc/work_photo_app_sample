import 'package:flutter/material.dart';

class BlackboardSetting extends StatelessWidget {
  const BlackboardSetting({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold：アプリの基本構造（AppBar・bodyなど）
    return Scaffold(
      appBar: AppBar(title: Text('黒板設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 余白
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 左揃え
          children: [
            // 事業名
            Text('事業名'),
            TextField(
              decoration: InputDecoration(
                hintText: '例：〇〇事業',
              ),
            ),
            SizedBox(height: 16), // 間隔

            // 現場名
            Text('現場名'),
            TextField(
              decoration: InputDecoration(
                hintText: '例：△△現場',
              ),
            ),
            SizedBox(height: 16),

            // 作業種（ドロップダウン）
            Text('作業種'),
            DropdownButtonFormField<String>(
              items: ['作業前', '作業中', '作業後']
                  .map((label) => DropdownMenuItem(
                value: label,
                child: Text(label),
              ))
                  .toList(),
              onChanged: (value) {
                // 今は何も処理しない
              },
              decoration: InputDecoration(
                hintText: '選択してください',
              ),
            ),
            SizedBox(height: 16),

            // 林小班
            Text('林小班'),
            TextField(
              decoration: InputDecoration(
                hintText: '例：1-2',
              ),
            ),
            SizedBox(height: 24),

            // 保存ボタン
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // 保存処理はまだ未実装
                },
                child: Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
