import 'package:logger/logger.dart';
import 'file_log_output.dart';

// loggerを初期化して使う準備をする関数

Future<Logger> createAppLogger() async {
  // ファイル出力に必要な機能を自作したものを動かし、ログの出力先を設定
  // FileLogOutput.create();でディレクトリ存在チェック+パス+ファイル名+outputメソッドを設定したインスタンスをoutputに格納する
  final output = await FileLogOutput.create();
  return Logger(
    // ログの見た目を整える（🐛や⚠️などアイコンや整形付きで出力）
    printer: PrettyPrinter(),
    // ログの書き込み処理を持つインスタンスを渡す
    output: output,
  );
}

// Loggerの引数について
//
// 名前を指定して渡せる
// Logger({
//   LogFilter? filter,
//   LogPrinter? printer,
//   LogOutput? output,
//   Level? level,
// });
//
// 各名前付き引数について
// filter：どのレベル（debug/info/errorなど）のログを出すか？ を決める。
// 　　　　　デフォは通常は DevelopmentFilter() が使われます（デフォルトで debug 以上を表示）
// 　　　　　本番では ProductionFilter() で warning や error だけに絞ることも
//         Logger(filter: ProductionFilter());  // info 以下は無視
//
// 　　　　　コードで細かく出力条件を指定できる（レベル以外の条件もできることがlevelとのちがい）
// 　　　　　
// printer：ログの見た目を整える（整形処理）
// 　　　　　Logger(printer: PrettyPrinter());   // ← 🐛⚠️ 付きできれい
// 　　　　　Logger(printer: SimplePrinter());   // ← シンプルなテキストのみ
//
// output: ログの書き込み処理を持つインスタンスを渡す
// 　　　　　例：コンソール（標準）／ファイル（今回）／Firebase など
// 　　　　　今回は「FileLogOutput.create();でディレクトリ存在チェック+パス+ファイル名+outputメソッドを設定したインスタンスを渡してるので、指定したファイルに正しく書き込まれる」
// 　　　　　
// level：ログの「最低レベル（しきい値）」を決める
// 　　　　「このレベル未満は出さない」と宣言する（数値的に制御）
//         Logger(level: Level.warning);