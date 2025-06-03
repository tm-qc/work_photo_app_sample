import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../utils/global_logger.dart';
import 'display_picture_screen.dart';
import 'blackboard_widget.dart';

// カメラプレビューと黒板の表示・操作を行うメイン画面 StatefulWidget
// Flutterでは機能と画面を1つのWidgetにまとめるのが普通なので、カメラ＝画面のように扱うのでUI=Widgetで定義できる
// 機能：
// - カメラプレビューの表示
// - 黒板の移動・リサイズ
// - 写真撮影
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
  // ==============================================
  // 📱 カメラ関連の変数
  // ==============================================
  // カメラを制御するためのコントローラーを格納するプロパティを定義
  late CameraController _controller;
  // カメラ初期化の非同期処理:カメラ初期化処理の完了を待ってFuture型で受け取るプロパティを格納する変数
  late Future<void> _initializeControllerFuture;

  // ==============================================
  // 🎯 黒板の位置・サイズ管理用変数
  // ==============================================
  // 初期位置（bottom: 0）かどうか判定するための変数
  bool _isInitialPosition = true;

  // 黒板の位置を保持（初期は左下付近）
  // offset:Stackの中での相対位置。今回はカメラプレビュー内になる。Stack内のPositionedで使われてる
  Offset _blackboardPosition = const Offset(0, 0);

  // 黒板のサイズを格納するためのGlobalKey
  // ウィジェットの位置やサイズを取得するためには、GlobalKeyを使ってアクセスする
  final GlobalKey _blackboardKey = GlobalKey();

  // 拡大縮小用の変数
  // double _scale = 1.0;
  // double _baseScale = 1.0;

  // ドラッグ用の変数
  // Offset _basePosition = Offset.zero;
  // Offset _startFocalPoint = Offset.zero;

  // ==============================================
  // 📏 リサイズ機能用の変数
  // ==============================================
  double _blackboardWidth = 200.0;// 黒板の幅
  double _blackboardHeight = 150.0;// 黒板の高さ
  bool _isDragging = false;// 移動中フラグ
  bool _isResizing = false;// リサイズ中フラグ
  String _resizeMode = '';// どの角をリサイズ中か（'topLeft', 'topRight'など）

  // ==============================================
  // 🎯 ドラッグ操作時の初期値保存用変数
  // ==============================================
  Offset _dragStartPosition = Offset.zero;// ドラッグ開始時のタッチ座標
  Size _dragStartSize = Size.zero;// ドラッグ開始時の黒板サイズ
  Offset _dragStartBlackboardPosition = Offset.zero;// ドラッグ開始時の黒板座標


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
    // 初期化が終わるまでは CameraPreview を表示しないようにする
    // try-catchでエラーに備えて、初期化を実行
    try {
      // コントローラーを初期化（非同期処理）_controller.initialize()はFutureを返します
      // _controller.initialize()はCameraController クラス（cameraパッケージ）に定義されているメソッド
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
  // dispose() は Flutterのライフサイクルで「終了処理」の時に自動で起動する
  void dispose() {
    // Widgetが破棄されるときに、カメラコントローラーも解放
    _controller.dispose();
    super.dispose();
  }

  // ==============================================
  // 🔧 四隅ハンドル（リサイズ用）の処理メソッド群
  // ==============================================

  // 四隅ハンドルのドラッグ開始処理
  // [corner] どの角か（'topLeft', 'topRight', 'bottomLeft', 'bottomRight'）
  // [details] タッチ開始時の詳細情報
  void _handleCornerDragStart(String corner, DragStartDetails details) {
    print("🔧 リサイズ開始: $corner");
    setState(() {
      _isResizing = true;// リサイズモードON
      _resizeMode = corner;// どの角をリサイズ中かを記録
      _dragStartPosition = details.globalPosition;// タッチ開始座標を記録
      _dragStartSize = Size(_blackboardWidth, _blackboardHeight);// 開始時のサイズを記録
      _dragStartBlackboardPosition = _blackboardPosition;// 開始時の位置を記録
    });
  }

  // 四隅ハンドルのドラッグ更新処理
  // リサイズの方向に応じて黒板のサイズと位置を調整
  //
  // ここのロジックはかなり難しい
  // 四隅それぞれで大きさ+ポジションを成り立たせる必要があって理解が追いつかない
  //
  // 【座標の基礎知識】
  // 基準は「座標系」です！
  // 根本的な理由
  //
  // 1. Flutter/画面の座標系
  //
  // 原点(0,0)は左上
  // X軸：右方向がプラス(+)
  // Y軸：下方向がプラス(+)
  //
  // 2. deltaの意味
  // delta = 現在位置 - 開始位置
  //
  // 右に移動 → delta.dx = +（プラス）
  // 左に移動 → delta.dx = -（マイナス）
  // 下に移動 → delta.dy = +（プラス）
  // 上に移動 → delta.dy = -（マイナス）
  void _handleCornerDragUpdate(DragUpdateDetails details) {
    if (!_isResizing) return; // リサイズ中でなければ何もしない

    // 現在のタッチ位置 - 開始時のタッチ位置 = 移動量
    final delta = details.globalPosition - _dragStartPosition;

    setState(() {
      switch (_resizeMode) {
        case 'topLeft':     // 左上角のリサイズ
          // 幅：左に引っ張ると幅が増加（delta.dxがマイナス）
          // clamp(min, max)：値を指定範囲内に制限するメソッドです。黒板が小さくなりすぎたり大きくなりすぎたりするのを防ぎます。
          // 左上開始位置より左に移動：delta.dxはマイナス値なので - で増加になる
          final newWidth = (_dragStartSize.width - delta.dx).clamp(100.0, 400.0);
          // 高さ：上に引っ張ると高さが増加（delta.dyがマイナス）
          // 左上開始位置より上に移動：delta.dyはマイナス値なので - で増加になる
          final newHeight = (_dragStartSize.height - delta.dy).clamp(80.0, 300.0);
          _blackboardWidth = newWidth;
          _blackboardHeight = newHeight;
          // 左上角をリサイズすると、位置も調整が必要（右下を固定点とする）
          _blackboardPosition = Offset(
            // 元の黒板の左上X座標 + (元の幅 - 新しい幅) = 新しい左上X座標
            _dragStartBlackboardPosition.dx + (_dragStartSize.width - newWidth),
            // 元の黒板の左上Y座標 + (元の高さ - 新しい高さ) = 新しい左上Y座標
            _dragStartBlackboardPosition.dy + (_dragStartSize.height - newHeight),
          );
          break;

        case 'topRight':    // 右上角のリサイズ
          // 幅：右に引っ張ると幅が増加（delta.dxがプラス）
          // 右上開始位置より右に移動：delta.dxはプラス値なので + で増加になる
          final newWidth = (_dragStartSize.width + delta.dx).clamp(100.0, 400.0);
          // 高さ：上に引っ張ると高さが増加（delta.dyがマイナス）
          // 右上開始位置より上に移動：delta.dyはマイナス値なので - で増加になる
          final newHeight = (_dragStartSize.height - delta.dy).clamp(80.0, 300.0);
          _blackboardWidth = newWidth;
          _blackboardHeight = newHeight;
          // 右上角リサイズでは、Y座標のみ調整（左下を固定点とする）
          _blackboardPosition = Offset(
            // X座標：左上のX座標は変更しない（左端を固定）
            _dragStartBlackboardPosition.dx,
            // Y座標：元の黒板の左上Y座標 + (元の高さ - 新しい高さ) = 新しい左上Y座標
            _dragStartBlackboardPosition.dy + (_dragStartSize.height - newHeight),
          );
          break;

        case 'bottomLeft':  // 左下角のリサイズ
          // 幅：左に引っ張ると幅が増加（delta.dxがマイナス）
          // 左下開始位置より左に移動：delta.dxはマイナス値なので - で増加になる
          final newWidth = (_dragStartSize.width - delta.dx).clamp(100.0, 400.0);
          // 高さ：下に引っ張ると高さが増加（delta.dyがプラス）
          // 左下開始位置より下に移動：delta.dyはプラス値なので + で増加になる
          final newHeight = (_dragStartSize.height + delta.dy).clamp(80.0, 300.0);
          _blackboardWidth = newWidth;
          _blackboardHeight = newHeight;
          // 左下角をリサイズすると、X座標のみ調整が必要（右上を固定点とする）
          _blackboardPosition = Offset(
            // X座標：元の黒板の左上X座標 + (元の幅 - 新しい幅) = 新しい左上X座標
            _dragStartBlackboardPosition.dx + (_dragStartSize.width - newWidth),
            // Y座標：左上のY座標は変更しない（上端を固定
            _dragStartBlackboardPosition.dy,
          );
          break;

        case 'bottomRight': // 右下角のリサイズ
          // 右下角は最もシンプル：左上を固定点として拡大縮小
          // 幅：右に引っ張ると幅が増加（delta.dxがプラス）
          // 右下開始位置より右に移動：delta.dxはプラス値なので + で増加になる
          _blackboardWidth = (_dragStartSize.width + delta.dx).clamp(100.0, 400.0);
          // 高さ：下に引っ張ると高さが増加（delta.dyがプラス）
          // 右下開始位置より下に移動：delta.dyはプラス値なので + で増加になる
          _blackboardHeight = (_dragStartSize.height + delta.dy).clamp(80.0, 300.0);
          // 位置調整右下だけ不要な理由
          // 右下角は「左上を固定点」として拡大縮小するため、左上の位置（_blackboardPosition）は変更する必要がありません
          // 位置調整は不要
          break;
      }
    });
    print("📏 リサイズ中: ${_blackboardWidth.toInt()}x${_blackboardHeight.toInt()}");
  }

  // 四隅ハンドルのドラッグ終了処理
  void _handleCornerDragEnd() {
    print("🔧 リサイズ終了: ${_blackboardWidth.toInt()}x${_blackboardHeight.toInt()}");
    setState(() {
      _isResizing = false; // リサイズモードOFF
      _resizeMode = '';    // リサイズモードをクリア
    });
  }

  // ==============================================
  // 🎨 UI部品作成メソッド
  // ==============================================

  // 四隅のリサイズハンドルを作成するメソッド
  // [corner] どの角か（'topLeft', 'topRight', 'bottomLeft', 'bottomRight'）
  // 戻り値：角丸配置済みのハンドルWidget
  Widget _buildCornerHandle(String corner) {
    return Positioned(
      // 角の位置に応じてtop/bottom、left/rightを設定
      // contains：文字列に特定の文字が含まれているかをチェックするメソッド（今回は引数のcornerに入ってる文字を見ている）

      // 角丸の描画位置をtop,bottom,left,rightそれぞれで設定
      top: corner.contains('top') ? -8 : null,     // 上側の角なら上端から-8px
      bottom: corner.contains('bottom') ? -8 : null, // 下側の角なら下端から-8px
      left: corner.contains('Left') ? -8 : null,   // 左側の角なら左端から-8px
      right: corner.contains('Right') ? -8 : null, // 右側の角なら右端から-8px
      child: GestureDetector(
        // ドラッグ操作のイベントハンドラを設定
        onPanStart: (details) => _handleCornerDragStart(corner, details),
        onPanUpdate: _handleCornerDragUpdate,
        onPanEnd: (_) => _handleCornerDragEnd(),

        // 角丸のレイアウト
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.blue,// ハンドルの色
            border: Border.all(color: Colors.white, width: 2),// 白い境界線
            borderRadius: BorderRadius.circular(8),// 角丸
          ),
        ),
      ),
    );
  }

  // ==============================================
  // 🏗️ メインのUI構築
  // ==============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('カメラプレビュー')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture, // カメラ初期化の完了を待つ
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // カメラ初期化完了：メインUIを表示
            //カメラと黒板を重ねて表示するためのStack
            return Stack(
              children: [
                // =======================================
                // 🎥 背景：カメラプレビュー
                // =======================================
                CameraPreview(_controller),

                // =======================================
                // 📊 デバッグ情報：現在の黒板のサイズ表示
                // =======================================
                Positioned(
                  top: 50,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '📏 ${_blackboardWidth.toInt()}×${_blackboardHeight.toInt()}',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),

                // =======================================
                // 🎯 メイン：黒板 + リサイズハンドル
                // =======================================
                Positioned(
                  // 📍 位置制御：初期位置 vs 絶対座標
                  left: _isInitialPosition ? 0 : _blackboardPosition.dx,
                  top: _isInitialPosition ? null : _blackboardPosition.dy,
                  bottom: _isInitialPosition ? 0 : null, // 初期位置では下端固定
                  child: Stack(
                    children: [
                      // ===============================
                      // 📱 黒板本体
                      // ===============================
                      GestureDetector(
                        behavior: HitTestBehavior.opaque, // タッチ検出を確実にする

                        // 🔥 重要：onScaleStart/Updateを使用
                        // これによりマルチタッチやピンチ操作も含めた統合的な処理が可能
                        onPanStart: (DragStartDetails details) {
                          if (_isResizing) return; // リサイズ中は移動処理をスキップ
                          print("スケール開始: focalPoint=${details.globalPosition}");

                          // 初期位置からの変換処理
                          if (_isInitialPosition) {
                            // 画面全体からドラッグしてるcontext(黒板)の位置を取得
                            final RenderBox? renderBox = _blackboardKey.currentContext?.findRenderObject() as RenderBox?;
                            // 現在のカメラプレビュー全体画面（TakePictureScreen）のルートウィジェットの描画情報
                            final RenderBox screenBox = context.findRenderObject() as RenderBox;
                            if (renderBox != null) {
                              // localToGlobal：黒板のローカル座標（Offset.zero = 左上）をancestor（ここでは画面全体screenBox）から見た絶対座標を取得
                              final blackboardPosition = renderBox.localToGlobal(Offset.zero, ancestor: screenBox);
                              print("🔧 初期位置変換: bottom配置 → 絶対座標${blackboardPosition}");
                              setState(() {
                                _isInitialPosition = false;
                                _blackboardPosition = blackboardPosition;
                                _dragStartPosition = details.globalPosition;
                                _dragStartBlackboardPosition = blackboardPosition;
                                _isDragging = true;
                              });
                            } else {
                              // フォールバック処理
                              final size = screenBox.size;
                              final fallbackPosition = Offset(0, size.height - _blackboardHeight);
                              setState(() {
                                _isInitialPosition = false;
                                _blackboardPosition = fallbackPosition;
                                _dragStartPosition = details.globalPosition;
                                _dragStartBlackboardPosition = fallbackPosition;
                                _isDragging = true;
                              });
                            }
                          } else {
                            // 通常の移動開始
                            setState(() {
                              _isDragging = true;
                              _dragStartPosition = details.globalPosition;
                              _dragStartBlackboardPosition = _blackboardPosition;
                            });
                          }
                        },

                        onPanUpdate: (DragUpdateDetails details) {
                          if (!_isDragging || _isResizing) return;
                          // 「開始時の黒板位置」+「指がどれだけ動いたか」=「新しい黒板位置」
                          // details.globalPosition: 現在のタッチ位置（グローバル座標）
                          // _dragStartPosition: ドラッグ開始時のタッチ位置
                          //
                          // details.globalPosition - _dragStartPosition: 指がどれだけ移動したか（移動量
                          final newPosition = _dragStartBlackboardPosition + (details.globalPosition - _dragStartPosition);
                          setState(() {
                            _blackboardPosition = newPosition;
                          });
                        },

                        onPanEnd: (DragEndDetails details)  {
                          print("スケール終了");
                          setState(() {
                            _isDragging = false;
                          });
                        },

                        child: Container(
                          key: _blackboardKey, // 座標取得用のGlobalKey
                          width: _blackboardWidth,
                          height: _blackboardHeight,
                          decoration: BoxDecoration(
                            // 操作中は青い境界線を表示（視覚的フィードバック）
                            border: _isResizing || _isDragging
                                ? Border.all(color: Colors.blue, width: 2)
                                : null,
                          ),
                          child: const BlackboardWidget(), // 実際の黒板コンテンツ
                        ),
                      ),

                      // ===============================
                      // 🔧 四隅のリサイズハンドル
                      // ===============================
                      // 四隅ドラッグの拡大縮小に必要な引数
                      //
                      // _buildCornerHandleに渡す第一引数(String corner)の利用箇所について
                      // - _buildCornerHandle:ハンドル描画メソッド
                      // - _buildCornerHandle：四隅ハンドルのドラッグ開始処理でどこの角か？を渡してる
                      // - _handleCornerDragUpdate:四隅ハンドルのドラッグ中の縮小拡大の処理の判別でどこの角か？を_buildCornerHandleから受け取っている
                      // TODO:引数の引き渡しが多く、依存度が高いように感じるので、メソッドのファイル分け整理後に改善が必要かもしれない
                      _buildCornerHandle('topLeft'),     // 左上
                      _buildCornerHandle('topRight'),    // 右上
                      _buildCornerHandle('bottomLeft'),  // 左下
                      _buildCornerHandle('bottomRight'), // 右下
                    ],
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            // カメラ初期化エラー時の表示
            return const Center(
              child: Text('カメラの初期化に失敗しました'),
            );
          } else {
            // カメラ初期化中の表示
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),

      // =======================================
      // 📸 撮影ボタン（FloatingActionButton）
      // =======================================
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            // カメラ初期化完了を待つ
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
              // 撮影した写真を表示する画面へ遷移
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DisplayPictureScreen(imagePath: image.path),
                ),
              );
            }
          } catch (e) {
            logger.e('写真撮影に失敗しました: $e');
          }
        },
        child: const Icon(Icons.camera_alt), // カメラアイコン
      )
    );
  }


}

