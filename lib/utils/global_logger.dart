
import 'package:logger/logger.dart';
// グローバルで使えるlogger変数を定義
// ※main.dartは基本インポートしないのでここに定義
// ※main.dartは全体のエントリーポイント（起動ファイル）であり、依存されるべきではない

// ログを使うためのグローバル定義
// late
// 「あとから必ず初期化する（＝nullではない）」という前提の変数を宣言
// なお「！」のnull対策は開発者がnullではないと指定するだけなので、lateの方が良い
late Logger logger; // グローバル変数としてloggerを定義