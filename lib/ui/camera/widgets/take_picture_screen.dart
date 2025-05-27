import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../utils/global_logger.dart';
import 'display_picture_screen.dart';
import 'blackboard_widget.dart';

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
  bool _isInitialPosition = true;

  // 黒板の位置を保持（初期は左下付近）
  // offset:Stackの中での相対位置。今回はカメラプレビュー内になる。Stack内のPositionedで使われてる
  Offset _blackboardPosition = const Offset(0, 0);

  // 黒板のサイズを格納するためのGlobalKey
  // ウィジェットの位置やサイズを取得するためには、GlobalKeyを使ってアクセスする
  final GlobalKey _blackboardKey = GlobalKey();

  // 拡大縮小用の変数
  double _scale = 1.0;
  double _baseScale = 1.0;

  // ドラッグ用の変数
  Offset _basePosition = Offset.zero;
  Offset _startFocalPoint = Offset.zero;

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
  //
  // BuildContext contextどこからわたる？
  //　Flutterが context を自動で渡します
  // ↓こんな感じで呼び出されるが、ここで渡してるわけではなく、ビルドの時に自動で渡るらしいです
  // builder: (context) => TakePictureScreen(camera: firstCamera),
  Widget build(BuildContext context) {
    // final Size previewSize = MediaQuery.of(context).size;
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
                // ✅変更：黒板を動かせるように修正
                Positioned(
                  // カメラプレビュー表示タイミングの黒板の初期位置を左下に固定、ドラッグ後は自由な位置
                  left: _isInitialPosition ? 0 : _blackboardPosition.dx,
                  top: _isInitialPosition ? null : _blackboardPosition.dy,
                  bottom: _isInitialPosition ? 0 : null, //これでカメラプレビュー内の左下に固定
                  // GestureDetector：ユーザーの操作（タップ・ドラッグなど）を検知するためのウィジェット
                  child: GestureDetector(

                    onScaleStart: (ScaleStartDetails details) {
                      print("スケール開始: focalPoint=${details.focalPoint}");
                      // フォーカルポイントの開始位置を記録
                      _startFocalPoint = details.focalPoint;

                      if (_isInitialPosition) {
                        // 黒板の情報
                        // _blackboardKey は GlobalKey なので、画面全体からドラッグしてるcontext(黒板)の位置を取得
                        // as RenderBox：型をRenderBoxにキャスト
                        final RenderBox? renderBox = _blackboardKey.currentContext?.findRenderObject() as RenderBox?;

                        // 現在のカメラプレビュー全体画面（TakePictureScreen）のルートウィジェットの描画情報
                        // 黒板のローカル座標を「この画面の中でのどこ？」という絶対座標に変換するために下のancestorで使います
                        final RenderBox screenBox = context.findRenderObject() as RenderBox;

                        if (renderBox != null) {
                          // 黒板の左上（0,0）が、画面全体の中でどこにあるか？を計算し座標を取得する
                          // (= 初期状態で bottom:0 で表示されているカメラプレビュー内の左下)

                          // これでドラッグした瞬間にこの値で黒板が設置されることで、初動で位置がぶれなくなる
                          //
                          // renderBox：黒板の情報
                          // localToGlobal：黒板のローカル座標（Offset.zero = 左上）をancestor（ここでは画面全体screenBox）から見た絶対座標を取得
                          // ※localToGlobal＝ローカル座標から絶対座標を取得するメソッド。globalToLocalもある
                          // ※ancestor：このウィジェットの座標を、どの親（祖先）から見た基準で測るか？
                          final blackboardPosition = renderBox.localToGlobal(Offset.zero, ancestor: screenBox);
                          setState(() {
                            _isInitialPosition = false;
                            // 初期状態では bottom:0 で左下に置かれているので、
                            // そのときの実際の座標を保存し、ドラッグ時の表示ブレを防ぐ
                            _blackboardPosition = blackboardPosition;
                            // 追加
                            _basePosition = blackboardPosition;
                          });
                        // 万が一 renderBox が取得できなかった場合のフォールバック処理
                        // 理論上は起きないが、保険として安全策
                        // ここにくる場合はドラッグの初動がずれる
                        }else{
                          final size = screenBox.size;
                          setState(() {
                            _isInitialPosition = false;
                            // 推定位置を使用
                            _blackboardPosition = Offset(0, size.height - (size.height * 0.2)); // (size.height * 0.2)は黒板の実際の高さ
                            // _blackboardPosition = Offset(0, size.height - 100); // 100は黒板の推定高さ
                            // 追加
                            _basePosition = _blackboardPosition;
                          });
                        }
                      }else{
                        // 追加
                        // 既に自由移動モードの場合、現在の位置を基準として保存
                        _basePosition = _blackboardPosition;
                      }
                      // 現在のスケールを基準として保存
                      _baseScale = _scale;
                    },

                    onScaleUpdate: (ScaleUpdateDetails details) {
                      if (!_isInitialPosition) {
                        setState(() {
                          // 拡大縮小の処理
                          double newScale = _baseScale * details.scale;
                          // スケールの制限を適用
                          newScale = newScale.clamp(0.5, 3.0);
                          _scale = newScale;

                          // ドラッグの処理（開始位置からの差分を計算）
                          final dragDelta = details.focalPoint - _startFocalPoint;
                          _blackboardPosition = _basePosition + dragDelta;

                          print("スケール中: scale=${details.scale}, 実際のスケール=${_scale}, position=${_blackboardPosition}");
                        });
                      }
                    },

                    onScaleEnd: (ScaleEndDetails details) {
                      print("スケール終了: scale=${_scale}");
                    },
                    child: Transform.scale(
                      scale: _scale,
                      // スケールの中心点を設定（デフォルトはcenter）
                      alignment: Alignment.center,
                      child: Container(
                        key: _blackboardKey,
                        child: const BlackboardWidget(),
                      ),
                    ),
                  ),
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

}

