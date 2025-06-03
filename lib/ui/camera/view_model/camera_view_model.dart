import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../domain/models/camera_model.dart';
import '../../../data/services/camera_service.dart';
import '../../../utils/global_logger.dart';

/// カメラ画面のViewModel（ChangeNotifier）
///
/// 【🔧 重要な変更】
/// BlackboardServiceを使わず、元のコードのロジックを直接ViewModelに実装
/// これにより元のコードと同じ動作を保証
class CameraViewModel extends ChangeNotifier {

  // ==============================================
  // 🔧 サービス依存関係
  // ==============================================

  /// カメラ操作を担当するサービス
  /// カメラの初期化・撮影・リソース管理を委譲
  final CameraService _cameraService;

  /// 現在の状態を保持するModel
  /// UIはこのModelの値を参照して描画
  CameraModel _state;

  // ==============================================
  // 🏗️ コンストラクタ・初期化
  // ==============================================

  /// ViewModelのコンストラクタ
  CameraViewModel({
    CameraService? cameraService,
  })  : _cameraService = cameraService ?? CameraService(),
        _state = CameraModel();

  // ==============================================
  // 📊 状態アクセサ（Getter）
  // ==============================================

  /// 現在の状態を取得（読み取り専用）
  CameraModel get state => _state;

  /// カメラコントローラーを取得（読み取り専用）
  CameraController? get controller => _state.controller;

  /// カメラ初期化Futureを取得（読み取り専用）
  Future<void>? get initializeFuture => _state.initializeControllerFuture;

  /// 黒板の現在位置を取得
  Offset get blackboardPosition => _state.blackboardPosition;

  /// 黒板の現在サイズを取得
  Size get blackboardSize => Size(_state.blackboardWidth, _state.blackboardHeight);

  /// 初期位置かどうかを取得
  bool get isInitialPosition => _state.isInitialPosition;

  /// ドラッグ中かどうかを取得
  bool get isDragging => _state.isDragging;

  /// リサイズ中かどうかを取得
  bool get isResizing => _state.isResizing;

  /// 黒板のGlobalKeyを取得
  GlobalKey get blackboardKey => _state.blackboardKey;

  // ==============================================
  // 📱 カメラ関連の操作メソッド
  // ==============================================

  /// カメラの初期化
  Future<void> initializeCamera(
      CameraDescription camera, {
        ResolutionPreset resolutionPreset = ResolutionPreset.medium,
      }) async {
    try {
      logger.i('カメラ初期化を開始します');

      // CameraServiceに初期化を委譲
      await _cameraService.initializeCamera(camera, resolutionPreset: resolutionPreset);

      // 初期化成功：Modelにカメラ情報を設定
      _state.controller = _cameraService.controller!;
      _state.initializeControllerFuture = _cameraService.initializeFuture!;

      // UI更新を通知
      notifyListeners();

      logger.i('カメラ初期化が完了しました');

    } catch (e) {
      logger.e('カメラ初期化に失敗しました: $e');

      // 初期化失敗：エラー状態のModelを設定
      _state.initializeControllerFuture = Future.error(e);

      // UI更新を通知
      notifyListeners();

      // エラーを再スロー（Screen側でキャッチ可能）
      rethrow;
    }
  }

  /// 写真撮影
  Future<XFile> takePicture() async {
    try {
      logger.i('写真撮影を開始します');

      // CameraServiceに撮影処理を委譲
      final XFile image = await _cameraService.takePicture();

      logger.i('写真撮影が完了しました: ${image.path}');
      return image;

    } catch (e) {
      logger.e('写真撮影に失敗しました: $e');
      rethrow;
    }
  }

  /// カメラの利用可能性チェック
  bool isCameraAvailable() {
    return _cameraService.isAvailable();
  }

  // ==============================================
  // 🎯 黒板移動関連の操作メソッド（元のコードから直接移植）
  // ==============================================

  /// 黒板移動の開始処理
  ///
  /// 【🔧 重要】
  /// 元のonPanStartロジックを完全に移植
  /// setState()をnotifyListeners()に置き換えただけ
  void onPanStart(DragStartDetails details, BuildContext context) {
    if (_state.isResizing) return; // リサイズ中は移動処理をスキップ
    print("スケール開始: focalPoint=${details.globalPosition}");

    // 🔧 元のコードと完全に同じ初期位置変換処理
    if (_state.isInitialPosition) {
      // 画面全体からドラッグしてるcontext(黒板)の位置を取得
      final RenderBox? renderBox = _state.blackboardKey.currentContext?.findRenderObject() as RenderBox?;
      // 現在のカメラプレビュー全体画面（TakePictureScreen）のルートウィジェットの描画情報
      final RenderBox screenBox = context.findRenderObject() as RenderBox;
      if (renderBox != null) {
        // localToGlobal：黒板のローカル座標（Offset.zero = 左上）をancestor（ここでは画面全体screenBox）から見た絶対座標を取得
        final blackboardPosition = renderBox.localToGlobal(Offset.zero, ancestor: screenBox);
        print("🔧 初期位置変換: bottom配置 → 絶対座標${blackboardPosition}");

        // 🔧 元のsetState()と同じ効果をnotifyListeners()で実現
        _state.isInitialPosition = false;
        _state.blackboardPosition = blackboardPosition;
        _state.dragStartPosition = details.globalPosition;
        _state.dragStartBlackboardPosition = blackboardPosition;
        _state.isDragging = true;
        notifyListeners();
      } else {
        // フォールバック処理
        final size = screenBox.size;
        final fallbackPosition = Offset(0, size.height - _state.blackboardHeight);

        _state.isInitialPosition = false;
        _state.blackboardPosition = fallbackPosition;
        _state.dragStartPosition = details.globalPosition;
        _state.dragStartBlackboardPosition = fallbackPosition;
        _state.isDragging = true;
        notifyListeners();
      }
    } else {
      // 通常の移動開始
      _state.isDragging = true;
      _state.dragStartPosition = details.globalPosition;
      _state.dragStartBlackboardPosition = _state.blackboardPosition;
      notifyListeners();
    }
  }

  /// 黒板移動の更新処理
  ///
  /// 【🔧 重要】
  /// 元のonPanUpdateロジックを完全に移植
  void onPanUpdate(DragUpdateDetails details) {
    if (!_state.isDragging || _state.isResizing) return;

    // 🔧 元のコードと完全に同じ計算
    // 「開始時の黒板位置」+「指がどれだけ動いたか」=「新しい黒板位置」
    // details.globalPosition: 現在のタッチ位置（グローバル座標）
    // _dragStartPosition: ドラッグ開始時のタッチ位置
    //
    // details.globalPosition - _dragStartPosition: 指がどれだけ移動したか（移動量
    final newPosition = _state.dragStartBlackboardPosition + (details.globalPosition - _state.dragStartPosition);

    _state.blackboardPosition = newPosition;
    notifyListeners();
  }

  /// 黒板移動の終了処理
  ///
  /// 【🔧 重要】
  /// 元のonPanEndロジックを完全に移植
  void onPanEnd(DragEndDetails details) {
    print("スケール終了");
    _state.isDragging = false;
    notifyListeners();
  }

  // ==============================================
  // 📏 黒板リサイズ関連の操作メソッド（元のコードから直接移植）
  // ==============================================

  /// 黒板リサイズの開始処理
  void onCornerDragStart(String corner, DragStartDetails details) {
    print("🔧 リサイズ開始: $corner");

    _state.isResizing = true;
    _state.resizeMode = corner;
    _state.dragStartPosition = details.globalPosition;
    _state.dragStartSize = Size(_state.blackboardWidth, _state.blackboardHeight);
    _state.dragStartBlackboardPosition = _state.blackboardPosition;
    notifyListeners();
  }

  /// 黒板リサイズの更新処理
  void onCornerDragUpdate(DragUpdateDetails details) {
    if (!_state.isResizing) return;

    // 現在のタッチ位置 - 開始時のタッチ位置 = 移動量
    final delta = details.globalPosition - _state.dragStartPosition;

    // 🔧 元のコードと同じswitch文による角別処理
    switch (_state.resizeMode) {
      case 'topLeft':
        final newWidth = (_state.dragStartSize.width - delta.dx).clamp(100.0, 400.0);
        final newHeight = (_state.dragStartSize.height - delta.dy).clamp(80.0, 300.0);
        _state.blackboardWidth = newWidth;
        _state.blackboardHeight = newHeight;
        _state.blackboardPosition = Offset(
          _state.dragStartBlackboardPosition.dx + (_state.dragStartSize.width - newWidth),
          _state.dragStartBlackboardPosition.dy + (_state.dragStartSize.height - newHeight),
        );
        break;

      case 'topRight':
        final newWidth = (_state.dragStartSize.width + delta.dx).clamp(100.0, 400.0);
        final newHeight = (_state.dragStartSize.height - delta.dy).clamp(80.0, 300.0);
        _state.blackboardWidth = newWidth;
        _state.blackboardHeight = newHeight;
        _state.blackboardPosition = Offset(
          _state.dragStartBlackboardPosition.dx,
          _state.dragStartBlackboardPosition.dy + (_state.dragStartSize.height - newHeight),
        );
        break;

      case 'bottomLeft':
        final newWidth = (_state.dragStartSize.width - delta.dx).clamp(100.0, 400.0);
        final newHeight = (_state.dragStartSize.height + delta.dy).clamp(80.0, 300.0);
        _state.blackboardWidth = newWidth;
        _state.blackboardHeight = newHeight;
        _state.blackboardPosition = Offset(
          _state.dragStartBlackboardPosition.dx + (_state.dragStartSize.width - newWidth),
          _state.dragStartBlackboardPosition.dy,
        );
        break;

      case 'bottomRight':
        _state.blackboardWidth = (_state.dragStartSize.width + delta.dx).clamp(100.0, 400.0);
        _state.blackboardHeight = (_state.dragStartSize.height + delta.dy).clamp(80.0, 300.0);
        break;
    }

    notifyListeners();
    print("📏 リサイズ中: ${_state.blackboardWidth.toInt()}x${_state.blackboardHeight.toInt()}");
  }

  /// 黒板リサイズの終了処理
  void onCornerDragEnd() {
    print("🔧 リサイズ終了: ${_state.blackboardWidth.toInt()}x${_state.blackboardHeight.toInt()}");
    _state.isResizing = false;
    _state.resizeMode = '';
    notifyListeners();
  }

  // ==============================================
  // 🧹 ライフサイクル管理
  // ==============================================

  @override
  void dispose() {
    logger.i('CameraViewModelのリソースを解放します');

    // CameraServiceのリソース解放
    _cameraService.disposeCamera();

    // Modelのリソース解放
    _state.dispose();

    // 親クラス（ChangeNotifier）のdispose処理も実行
    super.dispose();

    logger.i('CameraViewModelのリソース解放が完了しました');
  }
}