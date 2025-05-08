
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:work_photo_app_sample/main.dart' as app;

// サンプルに黒板設定画面の表示→入力→保存の結合テストを作成
void main() {
  // Integrationテスト用のバインディングを初期化（必須）
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('黒板設定画面の結合テスト', () {
    testWidgets('テキスト入力と保存の基本フロー', (tester) async {
      // アプリ全体を起動（main.dart の app.main() を実行）
      app.main();
      // 起動後のメニュー画面の描画完了を待つ
      await tester.pumpAndSettle();

      // 黒板設定テキスト＝ボタン存在確認
      expect(find.text('黒板設定'), findsOneWidget);

      // アプリ起動後、TOP画面の「黒板設定」ボタンをタップして画面遷移
      await tester.tap(find.text('黒板設定'));
      // TOPページから黒板設定画面への遷移待ち
      await tester.pumpAndSettle();

      // === UIの表示確認 ===

      // 各テキストフォームが表示されているかを確認

      // AppBarのテキストが黒板設定か？
      // 場所までみるこのようなテストは作成負荷やテストと厳格にすればするほど、UIの整合性が崩れやすくなる＝修正が増えるのであまりしなくていい
      expect(find.descendant(
          of: find.byType(AppBar),
          matching: find.text('黒板設定')
      ), findsOneWidget);

      // 一般的には以下のような理由でテキスト表示のチェック程度でOK
      //
      // - テストの作成負荷の観点から簡易的につくる
      // - 画面上にテキストがあるかだけ見て、場所はチェックしない
      // - 厳格に作りすぎると壊れやすくなりテストの修正頻度が増える
      //
      // テキスト表示のチェックだけで良い理由の補足
      // Flutterには「このテキストがこのTextFormFieldとセットか？」という機能は明確には存在しません。
      // なので、一般的には「順番」や「UI構造」で仮に強引に結びつけて考えるしかないので、テキスト表示をチェックする程度が一般的らしいです
      //
      // findsOneWidget:画面にちょうど1つだけ表示されていることを確認
      expect(find.text('事業名'), findsOneWidget);
      expect(find.text('現場名'), findsOneWidget);
      expect(find.text('作業種'), findsOneWidget);
      expect(find.text('林小班'), findsOneWidget);

      // === 入力処理 ===

      // テキストフォームに入力（TextFormFieldのindex指定などは実アプリに合わせて調整）
      await tester.enterText(find.byType(TextFormField).at(0), 'テスト事業');
      await tester.enterText(find.byType(TextFormField).at(1), 'テスト現場');
      await tester.enterText(find.byType(TextFormField).at(2), '小班1');

      // ドロップダウンメニュー（作業種）をタップして展開する
      // DropdownButtonFormField<int> は value が int型、表示は Map<int, String> で管理されているので、それで判別
      // ※判別条件がかぶる場合、他の判別手段は一般的にどうするのか気になるが、とりあえず今回はこれで
      // 　多分UIのKeyありきでする気はします
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      // 描画されるのを待つ
      await tester.pumpAndSettle();

      // 表示された選択肢の中から「作業前」という文字が表示された項目をタップ
      // これは内部的に value: 0 の項目に対応している（Map定義より）
      //
      // last は find.text('作業前') が複数ヒットしたときに、最後のものを選ぶために使います
      // .first	最初に見つかったもの
      // .at(1)	インデックス指定（例：2番目）
      // .last	最後に見つかったもの ← 今回使用
      await tester.tap(find.text('作業前').last); // 表示される選択肢からタップ
      // 描画されるのを待つ
      await tester.pumpAndSettle();

      // 保存ボタンをタップ（ラベルで探すか、UIにkeyがあればそれで指定もできる）
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // === 保存成功メッセージの確認 ===

      // SnackBarなどで成功メッセージが表示されるか確認
      expect(find.text('保存しました'), findsOneWidget); // 実際の表示メッセージに合わせて変更
    });
  });
}