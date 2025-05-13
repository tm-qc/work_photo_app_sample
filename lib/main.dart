import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:work_photo_app_sample/utils/global_logger.dart';
import 'package:work_photo_app_sample/utils/logger_factory.dart';
import 'config/camera_config.dart';
import 'top_menu.dart';

// 流れは
// 1. void mainでアプリ起動
// 2. MyAppがアプリのルートなど基盤の設定


// アプリを起動して、MyAppをルートウィジェットとして実行
void main() async {
  // WidgetsFlutterBinding.ensureInitialized();って？
  //
  // 「Flutterのバインディング（初期化）を先に確実にしてから非同期処理を行う」という正しい初期化の順序にする
  // awaitをmain()で使うときに必要らしい
  // 無い場合、不定期に予期せぬクラッシュが生まれることがあるらしい
  // main() 関数内で、runApp() が呼び出される前に、かつ非同期処理を開始する前に 呼び出すのが一般的
  WidgetsFlutterBinding.ensureInitialized();

  // 最初にロガーのインスタンスを作成しておくことでlogger.d()などログ出力が使えるようになる
  // logger使いた時は「import '../../utils/global_logger.dart';」をimportすればOK
  // ※現状ファイル書き込みの仕組みで作ってます
  logger = await createAppLogger(); // ロガーを作成して初期化

  // カメラの機能を使うためのアプリ起動時の準備

  // availableCameras()を使うためにアプリ起動時にインスタンスを作成する
  WidgetsFlutterBinding.ensureInitialized();

  // デバイスで使用可能なカメラのリストを取得します。
  // カメラ起動時にこのリストから正面や背面など何のカメラを起動するか選択する
  final cameras = await availableCameras();

  // 利用可能なカメラのリストから特定のカメラを取得します
  // first=背面カメラ
  // TODO:firstが背面とも限らないらしいので詳細はまたあとで
  firstCamera = cameras.firstWhere(
        // lensDirection で 背面カメラを明示的に選ぶ
        (camera) => camera.lensDirection == CameraLensDirection.back,
    // 万が一「背面カメラがない端末」でも orElse で fallback（前面カメラでも使えるように）
    orElse: () => cameras.first,
  );

  // カメラの機能を使うためのアプリ起動時の準備

  runApp(const MyApp());
}

// MyAppがアプリのルートなど基盤の設定
// 画面のテーマや最初に表示する画面(TopMenu)を指定する
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // アプリ名
      title: 'work_photo_app_sample',
      // ThemeDataとは
      // 全体的なビジュアルテーマを定義するクラス
      // これを設定すると、すべての画面に自動で適用される
      // ダークモードに対応も簡単に行えます
      //
      // 一般的に設定されるのは以下らしい
      //  - ベースとなるマテリアルデザイン:useMaterial3	Material3デザイン有効
      //  - 色 (Color) colorScheme	色の基本セット
      //  - フォント (Text) fontFamily　フォント指定
      //  - 文字 textTheme	テキストの大きさや色
      //  - アイコン (Icon) iconTheme アイコンの色、サイズ
      //  - ボタン (Button) elevatedButtonTheme Material3のボタンの色、形、余白
      // 　　※buttonTheme	Material2時代のボタン共通テーマ。Material3では非推奨
      //  - 画面上のタイトルバー appBarTheme	色・高さ
      //  - 入力欄 inputDecorationTheme	TextFieldなどの見た目
      //
      // ウィジェット内でテーマ情報は Theme.of(context) で取れる
      theme: ThemeData(
        // useMaterial3: trueとは？
        // 2025年現在、マテリアルデザインのMaterial3(MD3)を使うのがスタンダードらしい
        // それをベースに設定して使う
        //
        // マテリアルデザインとは？
        // Googleが提示するデザインテンプレート
        // WEB（HTML+CSS）で使われてるのと使い方が違うだけで同じもの
        //
        // 公式
        // useMaterial3プロパティについて
        // https://api.flutter.dev/flutter/material/ThemeData/useMaterial3.html
        //
        // Material Design
        // https://m3.material.io/
        //　
        // こんなのが今まであった
        // - Material Design：Google公式のスマホアプリ向けデザインガイドライン
        // - Material 2 (MD2)：昔のバージョン（Flutterも最初はこれ）
        // - Material 3 (MD3)：2021年以降の新しいデザインガイドライン、現在推奨
        useMaterial3: true,
        // colorSchemeとは
        // アプリ全体のテーマ（色など）を設定
        // アプリのベースカラーを設定
        //
        // fromSeed
        // ベースになる色（seedColor）から、自動で色のバリエーションを作る
        // 色の整合性が取れたテーマが作れる
        // 昔の書き方 primarySwatch: Colors.xxx
        //
        // この色たちが seedColor を基準に、自動で決まるらしい
        // primary	メイン色
        // secondary	アクセント色
        // background	背景色
        // error	エラー時の色
        // onPrimary	primaryの上に乗る文字色
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // デフォルト表示するページのクラスを設定
      home: TopMenu(),
    );
  }
}
