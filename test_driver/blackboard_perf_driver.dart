// 「flutter_driver」は非推奨
//
// 将来的にintegration_test パッケージにflutter_driverが統合されるので、25/05/08時点では「flutter_driver」は非推奨
// ただ、TimelineSummary など 一部の機能がまだ flutter_driver にしか無く、完全統合前でflutter_driverを使うしかない。
// integration_test パッケージに統合されたら、flutter_driveを削除するか、そのままflutter_driverを使うかのどちらかになる
//
// as＝別名（エイリアス）
// flutter_driver を driver という別名で使う（TimelineSummary などを呼び出すため）
import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

// Future
// async awaitを使うための型
//
// void
// returnなし
//
// 使い方
// 以下のコマンドでパフォーマンス計測実行したら呼ばれる
//
//flutter drive \
//--driver=test_driver/blackboard_perf_driver.dart \
//--target=integration_test/blackboard_setting_perf_test.dart \
//--profile \
//--no-dds
//
// --no-dds オプションを付けないと、Dart VM Service に接続できず、traceAction() が使えないため失敗します
//
// ログはどこに作成される？
// buildプロジェクトのルートにあるディレクトリに次の 2 つのファイルができます
Future<void> main() {
  // integrationDriver(): テスト実行時に呼ばれるエントリポイント関数
  // 引数 responseDataCallback に、テストから受け取ったデータを処理する関数を渡す
  return integrationDriver(
    responseDataCallback: (data) async {
      // テストから送られたパフォーマンスデータ（Map形式）が null でなければ処理
      if (data != null) {
        // Mapから 'blackboard_perf' キーに対応するデータ（タイムライン情報）を取得し、
        // flutter_driver の Timeline オブジェクトとして読み込む
        final timeline = driver.Timeline.fromJson(
          data['blackboard_perf'] as Map<String, dynamic>,
        );
        // Timeline オブジェクトを使ってサマリー（平均時間、最大時間など）を計算
        final summary = driver.TimelineSummary.summarize(timeline);

        // サマリーと詳細データをファイルとして出力
        // - ファイル名: blackboard_perf.timeline_summary.json / .timeline.json
        // - pretty: true → JSONを見やすく整形
        // - includeSummary: true → summaryもファイル出力
        await summary.writeTimelineToFile(
          'blackboard_perf',
          pretty: true,
          includeSummary: true,
        );
      }
    },
  );
}
