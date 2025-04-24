import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:work_photo_app_sample/config/labels.dart';
import 'package:work_photo_app_sample/ui/blackboard_setting/widgets/blackboard_setting_screen.dart';

void main() {
  // 初回描画共通関数
  Future<void> pumpBlackboardSettingScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      // 本番コードではlib/main.dartでMaterialAppを使っているが、テストの時はないので
      // マテリアルデザインの場合は必要になるらしい
      // Create the widget by telling the tester to build it.
      const MaterialApp(
        home: BlackboardSettingScreen(),
      ),
    );
    // UIに非同期描画がある場合には特に必要
    // こっちの方が非同期で待つので無難
    await tester.pumpAndSettle();
  }

  // ここからテスト
  group('黒板設定画面テスト', () {

    testWidgets('事業名表示テスト', (tester) async {
      await pumpBlackboardSettingScreen(tester);
      // 特定のWidgetが存在するかをチェック（例：事業名）
      expect(find.text(Labels.project), findsOneWidget); // Text('事業名')が画面にあるかを確認
    });

    testWidgets('事業名に空白だけを入力した状態でエラーメッセージが表示される', (tester) async {
      await pumpBlackboardSettingScreen(tester);
      // 空文字入力でこれはできないみたい
      // await tester.enterText(find.byType(TextFormField).first, '');
      // 空文字入力は空白文字で対応しないといけないので、バリデーション条件でtrimで空白文字をはじくしかない
      await tester.enterText(find.byType(TextFormField).first, ' ');
      // 入力の変更をUIに反映
      await tester.pumpAndSettle();
      // バリデーションエラーがリアルタイムで表示されることを確認
      expect(find.text('事業名は必須です'), findsOneWidget);
    });

    testWidgets('事業名は30文字を超えるとエラーメッセージが出る', (tester) async {
      await pumpBlackboardSettingScreen(tester);
      final tooLong = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほま'; // 31文字

      await tester.enterText(find.byType(TextFormField).first, tooLong);
      await tester.pumpAndSettle();
      // バリデーションエラーがリアルタイムで表示されることを確認
      expect(find.text('事業名は30文字以内で入力してください'), findsOneWidget);
    });

    testWidgets('事業名が空のまま送信するとバリデーションエラーが出ること', (tester) async {
      await pumpBlackboardSettingScreen(tester);
      // 保存ボタンをタップ
      await tester.tap(find.text('保存'));
      // 画面に変化を反映する（バリデーションメッセージなど）
      await tester.pumpAndSettle();
      // バリデーションメッセージが表示されているか
      expect(find.text('事業名は必須です'), findsOneWidget);
    });
  });
}