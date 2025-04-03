import 'package:flutter/material.dart';
import 'top_menu.dart';

// 流れは
// 1. void mainでアプリ起動
// 2. MyAppがアプリのルートなど基盤の設定

// アプリを起動して、MyAppをルートウィジェットとして実行
void main() {
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
