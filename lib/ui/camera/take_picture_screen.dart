import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../utils/global_logger.dart';
import 'display_picture_screen.dart';

// カメラを使って写真を撮影する画面を定義する StatefulWidget
// Flutterでは機能と画面を1つのWidgetにまとめるのが普通なので、カメラ＝画面のように扱うのでUI=Widgetで定義できる
class TakePictureScreen extends StatefulWidget {
  // コンストラクタ
  // camera という変数を外から必ず（required）受け取る
  const TakePictureScreen({super.key, required this.camera});

  // 利用するカメラ（前面カメラ or 背面カメラ）を外部から渡す
  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

// カメラの状態＝実態を管理するクラス
// この中でカメラの接続、表示、撮影の実行を担当します
class TakePictureScreenState extends State<TakePictureScreen> {
  // カメラを制御するためのコントローラーを格納するプロパティを定義
  late CameraController _controller;
  // カメラ初期化処理の完了を待ってFuture型で受け取るプロパティを定義
  late Future<void> _initializeControllerFuture;

  @override
  // 今回のカメラでなぜinitStateの上書きが必要なのか
  //
  // CameraControllerの作成、初期化を1回だけ行うために必要
  // build() に書くと？：毎回再描画のたびに初期化されてしまう → 無駄な処理＋カメラが不安定になる
  // initState() に書くと？：初回1回だけなので安定して初期化できる（Flutterの正しい使い方）
  void initState() {
    // initState() は Widget が表示される前に最初に1回だけ呼ばれる特別な処理
    // superはinitState() の「親クラスの初期処理もやっておいてね」という指定
    //
    // extends StateのクラスでinitStateメソッドを定義overrideするときに、
    // もとのinitStateも動かさないといけないので、メソッドの中にsuper.initState()が必須になる
    super.initState();
    // カメラの映像を表示・制御するための CameraController を作成
    // CameraController は camera パッケージが提供するクラス
    // カメラのON/OFF、プレビュー、撮影などすべての操作を担当するのがこのコントローラ
    // CameraControllerを初期化しないと、カメラを使ってプレビューを表示したり、写真を撮ったりすることができません。
    _controller = CameraController(
      // 利用するカメラ（TakePictureScreen から受け取ったカメラ情報）
      widget.camera,
      // 解像度設定（mediumは中程度の画質。low, medium, high など）
      ResolutionPreset.medium,
    );

    // カメラとの接続・初期化を非同期で行います
    // コントローラーを初期化（非同期処理）これはFutureを返します
    // 初期化が終わるまでは CameraPreview を表示しないようにする
    // _controller.initialize()はCameraController クラス（cameraパッケージ）に定義されているメソッド
    // try-catchでエラーに備えて、初期化を実行
    try {
      _initializeControllerFuture = _controller.initialize();
    } catch (e) {
      // カメラの初期化中にエラーが起きた場合にログを出力
      logger.e('カメラの初期化に失敗しました: $e');
      // ビューのsnapshot.hasErrorにtrueを渡しエラーだと伝える
      _initializeControllerFuture = Future.error(e);
    }
  }

  @override
  // メモリを無駄に使わないようにカメラを切断して解放します。
  // dispose() は Flutterのライフサイクルで「終了処理」の場所
  void dispose() {
    // Widgetが破棄されるときに、カメラコントローラーも解放
    _controller.dispose();
    super.dispose();
  }

  @override
  // build() メソッドは、Widgetの画面を構築するときに何度も呼ばれます。
  // この中で CameraPreview() などを返してUIを作ります
  // カメラのプレビューを表示する前に、コントローラが初期化されるまで待つ必要があります。
  // カメラのプレビューを表示する。 が初期化されるまで、FutureBuilderを使用してローディングスピナーを表示します。
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景は黒＋AppBar（任意で追加）
      appBar: AppBar(title: const Text('カメラプレビュー')),
      body: FutureBuilder<void>(
        // カメラ初期化が完了するまで待つ
        // 「_initializeControllerFuture（カメラ初期化処理）が完了するまで待って、
        // それが終わったら builder: 内のUIを表示
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            //カメラと黒板を重ねて表示するためのStack
            return Stack(
              children: [
                // 初期化が完了したらプレビューを表示
                CameraPreview(_controller), // 背景：カメラ

                // 黒板Widgetを左下に表示
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: _buildBlackboard(), // 黒板Widget（未設定と表示）
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text('カメラの初期化に失敗しました'),
            );
          } else {
            // 初期化中はローディングスピナーを表示
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),

      // 🟠 撮影ボタン（下に浮かぶボタン）+撮影後画像プレビュー画面表示
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            // カメラの初期化が完了しているか確認（未初期化で撮影すると例外になる）
            await _initializeControllerFuture;

            // カメラで写真を撮影し、一時保存された画像ファイルを取得（XFileとして返る）
            final XFile image = await _controller.takePicture();

            // この画面がまだ表示されている場合のみ（安全のため）
            // context(カメラプレビュー)がまだ表示されている場合のみというチェック
            //
            // なぜこのチェックが必要？
            // 撮影ボタン押した瞬間に、瞬間的にカメラがスワイプされて～というような瞬間的な事象のクラッシュをさけるため
            // レアケースだがあった方が安全
            if (context.mounted) {
              // 撮影した画像を表示する新しい画面に遷移（画像のパスを渡す）
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  // 撮影後の画像を表示するだけの画面
                    DisplayPictureScreen(imagePath: image.path),
                ),
              );
            }
          } catch (e) {
            logger.e('写真撮影に失敗しました: $e');
          }
        },
        // Icons.camera_altは既存のマテリアルデザインから使えるアイコン
        child: const Icon(Icons.camera_alt),
      )
    );
  }

  // 黒板
  // ★一般的に別ファイルにしない？
  Widget _buildBlackboard() {
    // MediaQuery.of
    // 今の画面サイズや表示情報（幅、高さ、文字サイズなど）を取得するための仕組み
    // MediaQuery.of(context) から取得できる情報はsize.height	画面の縦の長さなど他にもある
    final Size previewSize = MediaQuery.of(context).size;
    return Container(
      width: previewSize.width * 0.5, // 黒板の幅をプレビューの幅の半分に設定
      decoration: BoxDecoration(
        color: const Color(0xFF2E5E4E), // ダークグリーン背景
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 中身に必要な高さだけ取るように設定
        crossAxisAlignment: CrossAxisAlignment.stretch, // Container（親の枠）の幅横幅いっぱいに広げる
        children: [
          // 1行目：事業名
          Row(
            children: [
              // 事業名ラベル
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.white, width: 1),
                    bottom: BorderSide(color: Colors.white, width: 1),
                  ),
                ),
                child: const Text(
                  '事業名',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              // 事業名の値
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                  child: const Text(
                    '事業名の設定値',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),

          // 2行目：現場名と林小班を横に並べる
          IntrinsicHeight( // 高さを内容に合わせる
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 現場名ラベル
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.white, width: 1),
                      bottom: BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                  child: const Text(
                    '現場名',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                // 現場名の値
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.white, width: 1),
                        bottom: BorderSide(color: Colors.white, width: 1),
                      ),
                    ),
                    child: const Text(
                      '現場名の設定値',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                // 林小班ラベル
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.white, width: 1),
                      bottom: BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                  child: const Text(
                    '林小班',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                // 林小班の値
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 1),
                      ),
                    ),
                    child: const Text(
                      '林小班の設定値',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3行目：作業種の設定値
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
            alignment: Alignment.center,
            child: const Text(
              '作業種の設定値',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }


}