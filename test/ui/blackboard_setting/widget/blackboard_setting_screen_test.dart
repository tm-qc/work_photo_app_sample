import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:work_photo_app_sample/config/labels.dart';
import 'package:work_photo_app_sample/ui/blackboard_setting/widgets/blackboard_setting_screen.dart';

void main() {
  testWidgets('黒板設定画面(BlackboardSettingScreen)のUIテスト', (tester) async {

    // 非同期描画がある場合には必要らしい
    // await tester.pumpAndSettle(); // FutureBuilderやinit処理が終わるまで待つ

    // Create the widget by telling the tester to build it.
    await tester.pumpWidget(
        // 本番コードではlib/main.dartでMaterialAppを使っているが、テストの時はないので
        // マテリアルデザインの場合は必要になるらしい
        MaterialApp(
          home:const BlackboardSettingScreen(),
        ),
    );
    // 状態更新など非同期描画がある場合は以下を追加
    // await tester.pumpAndSettle(); // 全てのWidgetの描画完了を待つ
    // 特定のWidgetが存在するかをチェック（例：事業名）
    expect(find.text(Labels.project), findsOneWidget); // Text('事業名')が画面にあるかを確認
  });
}