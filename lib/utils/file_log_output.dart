// ファイル操作に必要なdart:ioライブラリ
// 組み込みのモジュールなのでデフォで使える
import 'dart:io';
// 保存先のフォルダパスを取得するためのパッケージ（Flutter公式推奨）
import 'package:path_provider/path_provider.dart';
// loggerパッケージの基本クラス（出力先をカスタムするために継承）
//
// なぜ必要なのか
// - logger パッケージは「どこにログを出力するか」を LogOutput で決めます
//   (通常はコンソール（print() みたいな）出力)
// - LogOutput クラスは「出力先の作り方を自由に拡張できる仕組み」なので、そこを extends（継承）して使う
// - 今回はログをファイルに書きたいから、それ専用の出力先クラス（FileLogOutput）を自作してLogOutputを継承して使うことでカスタムしてつかえる
import 'package:logger/logger.dart';

// このクラスは「loggerの出力先をファイルにして、パスの設定や書き込みロジックを定義したカスタム出力クラス」
class FileLogOutput extends LogOutput {
  late final File _file;

  // プライベートコンストラクタ（外部から直接 new できないようにする）
  //
  // どんな動き？
  // 外部から FileLogOutput() として直接呼ばれないようにできる
  // _ が先頭につく関数や変数は Dart では「外部からアクセスできない（プライベート）」という意味
  // create() メソッドからだけ安全にインスタンスを作らせたいときによく使うテクニックみたいです
  //
  // 例）通常のインスタンス化ができなくなる＝インポートしてcreateメソッドを呼ぶことでしかインスタンス化できなくなる
  // final f = FileLogOutput(file);
  // これはOK↓
  // final f = await FileLogOutput.create();
  //
  // なぜこれが必要？
  // create() メソッドが唯一の入り口になるように制限し、ただしくパスなどの設定を行わせる
  // これにより「安全に、正しい初期化（パス取得やフォルダ作成）を済ませてから使わせる」ことが保証される
  //
  // 複雑な初期化処理（非同期や複数ステップ）を中に閉じ込めて（カプセル化）安全にインスタンスを作成する一般的なセオリーらしい
  // （結構流れ把握難しいけど）
  FileLogOutput._(this._file);

  // ログ出力用ファイルを初期化する静的メソッド
  // logger_factory.dart から使われます（await FileLogOutput.create()）
  static Future<FileLogOutput> create() async {
    // アプリ専用の保存フォルダを取得
    // アプリが使ってよいローカルフォルダ（内部ストレージ）を取得する非同期関数
    // FlutterはiOSとAndroid両方対応なので、OSに依存しないこのAPIを使って安全な保存場所を取得する
    //
    // Android例: /data/data/パッケージ名/app_flutter/
    // 返ってくるのは Directory 型。
    // .path を使えば文字列のパスも取得できる
    final dir = await getApplicationDocumentsDirectory();

    // ログファイルの保存先の指定
    //
    // ${dir.path}ってどこ？
    //　プラットフォーム（Android/iOS）ごとに異なる「アプリ専用の保存フォルダ」
    //
    // Androidの場合の例
    // Android StudioのDevice Explorerで確認できる
    // /data/data/com.work_photo_app_sample.work_photo_app_sample/app_flutter
    //
    // VsCode StudioのDevice Explorerで確認する方法はコードで見るしかない
    // Android StudioのDevice ExplorerみたいにGUIで見る方法はないので、
    // GUI使いたいならVS CODEではなくAndroid Studioを併用する
    // 
    // TODO；最終的にはFirebaseのサーバーに格納予定

    // logsフォルダがなければ作成
    // logsフォルダが存在しないと、ログファイルが書き込めず失敗します
    // （エラーは表に出ないので気づきにくいです）
    final logDir = Directory('${dir.path}/logs');
    if (!(await logDir.exists())) {
      // create(recursive: true)なに？
      // 「存在しない親ディレクトリも含めてまとめて作る
      // 基本的にtrueで使う
      //
      // falseで使うことない
      // falseの場合、途中の親フォルダがない場合に失敗する
      //
      // trueで勝手に親フォルダが作られて事故が起きることはない？
      // →アプリの内部ストレージにおいて recursive: true は安全で推奨される使い方
      await logDir.create(recursive: true);
    }

    // File
    // ファイル操作用のクラス（dart:io）で、ファイルの読み書きを行うために使う
    // Fileインスタンスをパス+ファイル名を渡して生成する
    final file = File('${dir.path}/logs/app_log.txt');
    // このクラスのインスタンスを返す
    // プライベートコンストラクタ（FileLogOutput._()）を使って、自分自身のインスタンスを返す
    // このインスタンスをつかってメソッドを呼びファイルに書き込みする
    return FileLogOutput._(file);
  }

  // logger.dなどを使うと勝手に呼び出され、書き込み機能が動く
  // LogOutput を継承していれば必ず、内部的に output() を呼びます
  //
  // logger.dのほかには何がある？
  // ↓これが一般的に使うもの
  // - logger.d()	debug（デバッグ用）	🐛	開発中の動作確認ログ
  // - logger.i()	info（情報）	ℹ️	通常の処理成功など
  // - logger.w()	warning（警告）	⚠️	注意すべきことが起きた
  // - logger.e()	error（エラー）	⛔	例外や処理失敗など
  //
  // lib/utils/logger_factory.dartのLoggerのoutput引数に渡し、logger.dなどを動かすとここのvoid outputが呼び出されてファイルにログが書き込まれる
  // LogOutputを継承してるインスタンスをoutput引数に渡すとどこでlogger.dつかっても、ここのoutputが動く
  @override
  void output(OutputEvent event) {
    // 今回はファイル書き込み機能
    for (final line in event.lines) {
      // Firebase対応時は？
      // _file.writeAsStringSync() の部分を → FirebaseStorage.instance.ref('logs/app_log.txt').putFile(file) に変えるだけとのこと
      // TODO:Firebase全然知らないので後日調べる
      //
      // writeAsStringSync
      // 文字列（String）をファイルに書き込む処理を「同期的（Sync）」に実行する
      _file.writeAsStringSync('$line\n', mode: FileMode.append);
    }
  }
}
