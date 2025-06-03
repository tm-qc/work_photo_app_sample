import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../view_model/camera_view_model.dart';
import '../../../utils/global_logger.dart';
import 'display_picture_screen.dart';
import 'blackboard_widget.dart';

/// カメラプレビューと黒板の表示・操作を行うメイン画面 StatefulWidget
///
/// 【簡素化された役割】
/// - UIの描画のみに専念
/// - 全てのビジネスロジックをViewModelに委譲
/// - ユーザー操作をViewModelに転送
/// - ViewModelの状態変更を監視してUI更新
///
/// 【変更前との違い】
/// - 複雑な座標計算やリサイズロジックを削除
/// - ChangeNotifierでViewModelを監視
/// - UIイベントをViewModelメソッドに単純転送
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
/// 【簡素化された責任】
/// - ViewModelの初期化・解放
/// - ViewModelの状態変更監視
/// - UIイベントのViewModelへの転送
/// - 画面遷移の制御
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
  ///
  /// 【仕組み】
  /// ViewModelでnotifyListeners()が呼ばれると、
  /// この_onViewModelChangedが実行され、setState()でUI更新
  void _onViewModelChanged() {
    if (mounted) {  // 画面がまだ表示されている場合のみ更新
      setState(() {
        // ViewModelの状態が変更されたのでUIを再描画
      });
    }
  }

  /// カメラ初期化処理
  ///
  /// 【簡素化されたポイント】
  /// 複雑な初期化ロジックは全てViewModelに委譲
  /// エラーハンドリングもViewModelで実行
  Future<void> _initializeCamera() async {
    try {
      await _viewModel.initializeCamera(widget.camera);
    } catch (e) {
      // エラーログはViewModelで出力済み
      // 必要に応じて追加のエラーハンドリング
      logger.e('画面でのカメラ初期化エラー: $e');
    }
  }

  // ==============================================
  // 🎯 UI操作のViewModelへの転送
  // ==============================================

  /// 黒板移動開始処理
  ///
  /// 【簡素化されたポイント】
  /// 複雑な座標変換ロジックは削除
  /// ViewModelに処理を丸投げ
  void _handlePanStart(DragStartDetails details) {
    _viewModel.onPanStart(details, context);
  }

  /// 黒板移動更新処理
  ///
  /// 【簡素化されたポイント】
  /// 位置計算ロジックは削除
  /// ViewModelに処理を丸投げ
  void _handlePanUpdate(DragUpdateDetails details) {
    _viewModel.onPanUpdate(details);
  }

  /// 黒板移動終了処理
  ///
  /// 【簡素化されたポイント】
  /// 状態管理ロジックは削除
  /// ViewModelに処理を丸投げ
  void _handlePanEnd(DragEndDetails details) {
    _viewModel.onPanEnd(details);
  }

  /// 四隅ハンドルのドラッグ開始処理
  ///
  /// 【簡素化されたポイント】
  /// リサイズの複雑な計算ロジックは削除
  /// ViewModelに処理を丸投げ
  void _handleCornerDragStart(String corner, DragStartDetails details) {
    _viewModel.onCornerDragStart(corner, details);
  }

  /// 四隅ハンドルのドラッグ更新処理
  ///
  /// 【簡素化されたポイント】
  /// 座標系の複雑な計算は削除
  /// ViewModelに処理を丸投げ
  void _handleCornerDragUpdate(DragUpdateDetails details) {
    _viewModel.onCornerDragUpdate(details);
  }

  /// 四隅ハンドルのドラッグ終了処理
  ///
  /// 【簡素化されたポイント】
  /// 状態リセットロジックは削除
  /// ViewModelに処理を丸投げ
  void _handleCornerDragEnd() {
    _viewModel.onCornerDragEnd();
  }

  /// 写真撮影処理
  ///
  /// 【簡素化されたポイント】
  /// カメラ制御ロジックは削除
  /// ViewModelに処理を委譲し、結果の画面遷移のみ担当
  Future<void> _takePicture() async {
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
      // エラーログはViewModelで出力済み
      logger.e('画面での撮影エラー: $e');
    }
  }

  // ==============================================
  // 🎨 UI部品作成メソッド
  // ==============================================

  /// 四隅のリサイズハンドルを作成するメソッド
  ///
  /// 【簡素化されたポイント】
  /// UIの見た目のみに専念
  /// 操作ロジックは_handle系メソッドに委譲
  ///
  /// [corner] どの角か（'topLeft', 'topRight', 'bottomLeft', 'bottomRight'）
  /// 戻り値：角丸配置済みのハンドルWidget
  Widget _buildCornerHandle(String corner) {
    return Positioned(
      // 角の位置に応じてtop/bottom、left/rightを設定
      top: corner.contains('top') ? -8 : null,
      bottom: corner.contains('bottom') ? -8 : null,
      left: corner.contains('Left') ? -8 : null,
      right: corner.contains('Right') ? -8 : null,
      child: GestureDetector(
        // ドラッグ操作をViewModelに転送
        onPanStart: (details) => _handleCornerDragStart(corner, details),
        onPanUpdate: _handleCornerDragUpdate,
        onPanEnd: (_) => _handleCornerDragEnd(),

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

  /// デバッグ情報表示ウィジェット
  ///
  /// 【ViewModelの状態を表示】
  /// 現在の黒板サイズをViewModelから取得して表示
  Widget _buildDebugInfo() {
    final size = _viewModel.blackboardSize;
    return Positioned(
      top: 50,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '📏 ${size.width.toInt()}×${size.height.toInt()}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  /// 黒板本体ウィジェット
  ///
  /// 【簡素化されたポイント】
  /// 複雑な状態判定はViewModelから取得
  /// 操作処理は_handle系メソッドに委譲
  Widget _buildBlackboard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      // 移動操作をViewModelに転送
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,

      child: Container(
        key: _viewModel.blackboardKey,
        width: _viewModel.blackboardSize.width,
        height: _viewModel.blackboardSize.height,
        decoration: BoxDecoration(
          // 操作中の視覚的フィードバック
          // 状態判定をViewModelから取得
          border: _viewModel.isResizing || _viewModel.isDragging
              ? Border.all(color: Colors.blue, width: 2)
              : null,
        ),
        child: const BlackboardWidget(),
      ),
    );
  }

  /// 黒板とリサイズハンドルのStack
  ///
  /// 【簡素化されたポイント】
  /// 位置・サイズの状態をViewModelから取得
  /// レイアウトロジックのみに専念
  Widget _buildBlackboardWithHandles() {
    return Positioned(
      // 位置制御：ViewModelの状態を参照
      left: _viewModel.isInitialPosition ? 0 : _viewModel.blackboardPosition.dx,
      top: _viewModel.isInitialPosition ? null : _viewModel.blackboardPosition.dy,
      bottom: _viewModel.isInitialPosition ? 0 : null,
      child: Stack(
        children: [
          // 黒板本体
          _buildBlackboard(),

          // 四隅のリサイズハンドル
          _buildCornerHandle('topLeft'),
          _buildCornerHandle('topRight'),
          _buildCornerHandle('bottomLeft'),
          _buildCornerHandle('bottomRight'),
        ],
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
        // ViewModelから初期化Futureを取得
        future: _viewModel.initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // カメラ初期化完了：メインUIを表示
            return Stack(
              children: [
                // =======================================
                // 🎥 背景：カメラプレビュー
                // =======================================
                // ViewModelからcontrollerを取得
                if (_viewModel.controller != null)
                  CameraPreview(_viewModel.controller!),

                // =======================================
                // 📊 デバッグ情報
                // =======================================
                _buildDebugInfo(),

                // =======================================
                // 🎯 メイン：黒板 + リサイズハンドル
                // =======================================
                _buildBlackboardWithHandles(),
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
        // 撮影処理をViewModelに委譲
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}