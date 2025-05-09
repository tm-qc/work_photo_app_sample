import 'package:logger/logger.dart';

// テスト用のテストのログエラーを回避するためのログ初期化などのモックを作成
//
// ユニット、ウィジェットテストでログエラーがでる
// ログはビジネスロジックじゃないのでテスト不要
//
// 上記の理由でこのような対応にしました

// ログを無効にする出力先（どこにも出さない）
class MockLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // 出力しない
  }
}

// Logger初期化用のインスタンスを作って返す（テスト用）
Logger createMockLogger() {
  return Logger(
    // printer: PrettyPrinter(),    // 見た目は指定は出力しないので不要
    output: MockLogOutput(),     // ログを無効にする
  );
}
