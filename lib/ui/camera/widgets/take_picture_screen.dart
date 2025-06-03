import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../view_model/camera_view_model.dart';
import '../../../utils/global_logger.dart';
import 'display_picture_screen.dart';
import 'blackboard_widget.dart';

/// カメラプレビューと黒板の表示・操作を行うメイン画面 StatefulWidget
///
/// 【🔧 重要な変更】
/// 元のコードと全く同じScaffold + FutureBuilder構造を維持
/// ViewModelは状態管理のみに使用し、UI構造は変更しない
class TakePictureScreen extends StatefulWidget {
  /// コンストラクタ
  /// camera という変数を外から必ず（required）受け取る
  const TakePictureScreen({super.key, required this.camera});

  /// 利用するカメラ（前面カメラ or 背面カメラ）を外部から渡す
  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

/// カメラ画面の状態管理クラス（UI専用）
///
/// 【🔧 重要な変更】
/// 元のコードと同じbuild構造を維持
/// contextの参照先を元のコードと同じにする
class TakePictureScreenState extends State<TakePictureScreen> {

  // ==============================================
  // 🎯 ViewModel管理
  // ==============================================

  /// カメラ操作のViewModel
  /// 全てのビジネスロジックをこのViewModelに委譲
  late CameraViewModel _viewModel;

  // ==============================================
  // 🏗️ ライフサイクル管理
  // ==============================================

  @override
  void initState() {
    super.initState();

    // ViewModelを初期化
    _viewModel = CameraViewModel();

    // ViewModelの状態変更を監視（UI更新のため）
    _viewModel.addListener(_onViewModelChanged);

    // カメラ初期化をViewModelに委譲
    _initializeCamera();
  }

  @override
  void dispose() {
    // ViewModelの監視を停止
    _viewModel.removeListener(_onViewModelChanged);

    // ViewModelのリソースを解放
    _viewModel.dispose();

    super.dispose();
  }

  /// ViewModelの状態変更時にUIを更新
  void _onViewModelChanged() {
    if (mounted) {  // 画面がまだ表示されている場合のみ更新
      setState(() {
        // ViewModelの状態が変更されたのでUIを再描画
      });
    }
  }

  /// カメラ初期化処理
  Future<void> _initializeCamera() async {
    try {
      await _viewModel.initializeCamera(widget.camera);
    } catch (e) {
      // エラーログはViewModelで出力済み
      logger.e('画面でのカメラ初期化エラー: $e');
    }
  }

  // ==============================================
  // 🎨 UI部品作成メソッド（元のコードから移植）
  // ==============================================

  /// 四隅のリサイズハンドルを作成するメソッド
  ///
  /// 【元のコードから完全移植】
  /// UIの見た目は変更せず、操作のみViewModelに委譲
  Widget _buildCornerHandle(String corner) {
    return Positioned(
      // 角の位置に応じてtop/bottom、left/rightを設定
      top: corner.contains('top') ? -8 : null,
      bottom: corner.contains('bottom') ? -8 : null,
      left: corner.contains('Left') ? -8 : null,
      right: corner.contains('Right') ? -8 : null,
      child: GestureDetector(
        // ドラッグ操作をViewModelに転送
        onPanStart: (details) => _viewModel.onCornerDragStart(corner, details),
        onPanUpdate: _viewModel.onCornerDragUpdate,
        onPanEnd: (_) => _viewModel.onCornerDragEnd(),

        // 角丸のレイアウト（UIのみ）
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.blue,
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ==============================================
  // 🏗️ メインのUI構築（元のコードから完全移植）
  // ==============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('カメラプレビュー')),
      body: FutureBuilder<void>(
        // 🔧 重要：ViewModelからFutureを取得
        future: _viewModel.initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // カメラ初期化完了：メインUIを表示
            // 🔧 重要：元のコードと全く同じStack構造
            return Stack(
              children: [
                // =======================================
                // 🎥 背景：カメラプレビュー
                // =======================================
                // 🔧 重要：ViewModelからcontrollerを取得
                if (_viewModel.controller != null)
                  CameraPreview(_viewModel.controller!),

                // =======================================
                // 📊 デバッグ情報：現在の黒板のサイズ表示
                // =======================================
                Positioned(
                  top: 50,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '📏 ${_viewModel.blackboardSize.width.toInt()}×${_viewModel.blackboardSize.height.toInt()}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),

                // =======================================
                // 🎯 メイン：黒板 + リサイズハンドル
                // =======================================
                // 🔧 重要：元のコードと全く同じPositioned構造
                Positioned(
                  // 📍 位置制御：ViewModelの状態を参照
                  left: _viewModel.isInitialPosition ? 0 : _viewModel.blackboardPosition.dx,
                  top: _viewModel.isInitialPosition ? null : _viewModel.blackboardPosition.dy,
                  bottom: _viewModel.isInitialPosition ? 0 : null, // 初期位置では下端固定
                  child: Stack(
                    children: [
                      // ===============================
                      // 📱 黒板本体
                      // ===============================
                      // 🔧 重要：元のコードと全く同じGestureDetector
                      GestureDetector(
                        behavior: HitTestBehavior.opaque, // タッチ検出を確実にする

                        // 🔧 重要：onPanStart で context を渡す
                        // このcontextが元のコードと同じ参照先になる
                        onPanStart: (DragStartDetails details) {
                          _viewModel.onPanStart(details, context);
                        },

                        onPanUpdate: (DragUpdateDetails details) {
                          _viewModel.onPanUpdate(details);
                        },

                        onPanEnd: (DragEndDetails details) {
                          _viewModel.onPanEnd(details);
                        },

                        child: Container(
                          // 🔧 重要：ViewModelからGlobalKeyを取得
                          key: _viewModel.blackboardKey,
                          width: _viewModel.blackboardSize.width,
                          height: _viewModel.blackboardSize.height,
                          decoration: BoxDecoration(
                            // 操作中の視覚的フィードバック
                            border: _viewModel.isResizing || _viewModel.isDragging
                                ? Border.all(color: Colors.blue, width: 2)
                                : null,
                          ),
                          child: const BlackboardWidget(), // 実際の黒板コンテンツ
                        ),
                      ),

                      // ===============================
                      // 🔧 四隅のリサイズハンドル
                      // ===============================
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
            // 撮影処理をViewModelに委譲
            final XFile image = await _viewModel.takePicture();

            // 画面遷移のみScreenが担当
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DisplayPictureScreen(imagePath: image.path),
                ),
              );
            }
          } catch (e) {
            logger.e('写真撮影に失敗しました: $e');
          }
        },
        child: const Icon(Icons.camera_alt), // カメラアイコン
      ),
    );
  }
}