import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../domain/models/camera_model.dart';
import '../../../data/services/camera_service.dart';
import '../../../utils/global_logger.dart';

/// カメラ画面のViewModel（ChangeNotifier）
// BlackboardServiceを使わず、元のコードのロジックを直接ViewModelに実装
class CameraViewModel extends ChangeNotifier {

  // ==============================================
  // 🔧 サービス依存関係
  // ==============================================

  /// カメラ操作を担当するサービス
  /// カメラの初期化・撮影・リソース管理を委譲
  final CameraService _cameraService;

  /// 現在の状態を保持するModel
  /// UIはこのModelの値を参照して描画
  final CameraModel _model;

  // ==============================================
  // 🏗️ コンストラクタ・初期化
  // ==============================================

  /// ViewModelのコンストラクタ
  CameraViewModel({
    CameraService? cameraService,
  })  : _cameraService = cameraService ?? CameraService(),
        _model = CameraModel();

  // ==============================================
  // 📊 状態アクセサ（Getter）(get = 読み取り専用)
  // ==============================================

  /// カメラコントローラーを取得
  CameraController? get controller => _model.controller;

  /// カメラ初期化Futureを取得
  // 外部からinitializeFutureという名前でアクセスされたら、_model.initializeControllerFutureの値を返すゲッター
  Future<void>? get initializeFuture => _model.initializeControllerFuture;

  /// 黒板の現在位置を取得
  Offset get blackboardPosition => _model.blackboardPosition;

  /// 黒板の現在サイズを取得
  Size get blackboardSize => Size(_model.blackboardWidth, _model.blackboardHeight);

  /// 初期位置かどうかを取得
  bool get isInitialPosition => _model.isInitialPosition;

  /// ドラッグ中かどうかを取得
  bool get isDragging => _model.isDragging;

  /// リサイズ中かどうかを取得
  bool get isResizing => _model.isResizing;

  /// 黒板のGlobalKeyを取得
  GlobalKey get blackboardKey => _model.blackboardKey;

  // ==============================================
  // 📱 カメラ関連の操作メソッド
  // ==============================================

  /// カメラの初期化
  Future<void> initializeCamera(CameraDescription camera) async {
    try {
      logger.i('カメラ初期化を開始します');

      // CameraServiceに初期化を委譲
      await _cameraService.initializeCamera(camera);

      // 初期化成功：Modelにカメラ情報を設定
      _model.controller = _cameraService.controller!;
      _model.initializeControllerFuture = _cameraService.initializeFuture!;

      // UI更新を通知
      // モデルの状態が変わるタイミングは通知が必要
      notifyListeners();

      logger.i('カメラ初期化が完了しました');

    } catch (e) {
      logger.e('カメラ初期化に失敗しました: $e');

      // 初期化失敗：エラー状態のModelを設定
      _model.initializeControllerFuture = Future.error(e);

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
      // XFile:camera パッケージが提供するファイル型
      final XFile image = await _cameraService.takePicture();

      logger.i('写真撮影が完了しました: ${image.path}');
      return image;

    } catch (e) {
      logger.e('写真撮影に失敗しました: $e');
      rethrow;
    }
  }

  // ==============================================
  // 🎯 黒板移動関連の操作メソッド
  // ==============================================

  /// 黒板移動の開始処理
  void onPanStart(DragStartDetails details, BuildContext context) {
    if (_model.isResizing) return; // リサイズ中は移動処理をスキップ
    print("スケール開始: focalPoint=${details.globalPosition}");

    // 🔧 元のコードと完全に同じ初期位置変換処理
    if (_model.isInitialPosition) {
      // 画面全体からドラッグしてるcontext(黒板)の位置を取得
      final RenderBox? renderBox = _model.blackboardKey.currentContext?.findRenderObject() as RenderBox?;
      // 現在のカメラプレビュー全体画面（TakePictureScreen）のルートウィジェットの描画情報
      final RenderBox screenBox = context.findRenderObject() as RenderBox;
      if (renderBox != null) {
        // localToGlobal：黒板のローカル座標（Offset.zero = 左上）をancestor（ここでは画面全体screenBox）から見た絶対座標を取得
        final blackboardPosition = renderBox.localToGlobal(Offset.zero, ancestor: screenBox);
        print("🔧 初期位置変換: bottom配置 → 絶対座標$blackboardPosition");

        // 🔧 元のsetState()と同じ効果をnotifyListeners()で実現
        _model.isInitialPosition = false;
        _model.blackboardPosition = blackboardPosition;
        _model.dragStartPosition = details.globalPosition;
        _model.dragStartBlackboardPosition = blackboardPosition;
        _model.isDragging = true;
        notifyListeners();
      } else {
        // フォールバック処理
        final size = screenBox.size;
        final fallbackPosition = Offset(0, size.height - _model.blackboardHeight);

        _model.isInitialPosition = false;
        _model.blackboardPosition = fallbackPosition;
        _model.dragStartPosition = details.globalPosition;
        _model.dragStartBlackboardPosition = fallbackPosition;
        _model.isDragging = true;
        notifyListeners();
      }
    } else {
      // 通常の移動開始
      _model.isDragging = true;
      _model.dragStartPosition = details.globalPosition;
      _model.dragStartBlackboardPosition = _model.blackboardPosition;
      notifyListeners();
    }
  }

  /// 黒板移動の更新処理
  void onPanUpdate(DragUpdateDetails details) {
    if (!_model.isDragging || _model.isResizing) return;
    // 「開始時の黒板位置」+「指がどれだけ動いたか」=「新しい黒板位置」
    // details.globalPosition: 現在のタッチ位置（グローバル座標）
    // _dragStartPosition: ドラッグ開始時のタッチ位置
    //
    // details.globalPosition - _dragStartPosition: 指がどれだけ移動したか（移動量
    final newPosition = _model.dragStartBlackboardPosition + (details.globalPosition - _model.dragStartPosition);

    _model.blackboardPosition = newPosition;
    notifyListeners();
  }

  /// 黒板移動の終了処理
  void onPanEnd(DragEndDetails details) {
    print("スケール終了");
    _model.isDragging = false;
    notifyListeners();
  }

  // ==============================================
  // 📏 黒板リサイズ関連の操作メソッド（元のコードから直接移植）
  // ==============================================

  /// 黒板リサイズの開始処理
  void onCornerDragStart(String corner, DragStartDetails details) {
    print("🔧 リサイズ開始: $corner");

    _model.isResizing = true;
    _model.resizeMode = corner;
    _model.dragStartPosition = details.globalPosition;
    _model.dragStartSize = Size(_model.blackboardWidth, _model.blackboardHeight);
    _model.dragStartBlackboardPosition = _model.blackboardPosition;
    notifyListeners();
  }

  /// 黒板リサイズの更新処理
  ///
  /// 【重要な座標系の理解】
  ///
  /// Flutter画面座標系：
  /// - 原点(0,0)は左上
  /// - X軸：右方向がプラス(+)
  /// - Y軸：下方向がプラス(+)
  ///
  /// 【Delta計算】
  /// delta = 現在位置 - 開始位置
  /// - 右に移動 → delta.dx = +（プラス）
  /// - 左に移動 → delta.dx = -（マイナス）
  /// - 下に移動 → delta.dy = +（プラス）
  /// - 上に移動 → delta.dy = -（マイナス）
  void onCornerDragUpdate(DragUpdateDetails details) {
    if (!_model.isResizing) return;

    // 現在のタッチ位置 - 開始時のタッチ位置 = 移動量
    final delta = details.globalPosition - _model.dragStartPosition;

    // 🔧 元のコードと同じswitch文による角別処理
    switch (_model.resizeMode) {
      case 'topLeft':
        final newWidth = (_model.dragStartSize.width - delta.dx).clamp(100.0, 400.0);
        final newHeight = (_model.dragStartSize.height - delta.dy).clamp(80.0, 300.0);
        _model.blackboardWidth = newWidth;
        _model.blackboardHeight = newHeight;
        _model.blackboardPosition = Offset(
          _model.dragStartBlackboardPosition.dx + (_model.dragStartSize.width - newWidth),
          _model.dragStartBlackboardPosition.dy + (_model.dragStartSize.height - newHeight),
        );
        break;

      case 'topRight':
        final newWidth = (_model.dragStartSize.width + delta.dx).clamp(100.0, 400.0);
        final newHeight = (_model.dragStartSize.height - delta.dy).clamp(80.0, 300.0);
        _model.blackboardWidth = newWidth;
        _model.blackboardHeight = newHeight;
        _model.blackboardPosition = Offset(
          _model.dragStartBlackboardPosition.dx,
          _model.dragStartBlackboardPosition.dy + (_model.dragStartSize.height - newHeight),
        );
        break;

      case 'bottomLeft':
        final newWidth = (_model.dragStartSize.width - delta.dx).clamp(100.0, 400.0);
        final newHeight = (_model.dragStartSize.height + delta.dy).clamp(80.0, 300.0);
        _model.blackboardWidth = newWidth;
        _model.blackboardHeight = newHeight;
        _model.blackboardPosition = Offset(
          _model.dragStartBlackboardPosition.dx + (_model.dragStartSize.width - newWidth),
          _model.dragStartBlackboardPosition.dy,
        );
        break;

      case 'bottomRight':
        _model.blackboardWidth = (_model.dragStartSize.width + delta.dx).clamp(100.0, 400.0);
        _model.blackboardHeight = (_model.dragStartSize.height + delta.dy).clamp(80.0, 300.0);
        break;
    }

    notifyListeners();
    print("📏 リサイズ中: ${_model.blackboardWidth.toInt()}x${_model.blackboardHeight.toInt()}");
  }

  /// 黒板リサイズの終了処理
  void onCornerDragEnd() {
    print("🔧 リサイズ終了: ${_model.blackboardWidth.toInt()}x${_model.blackboardHeight.toInt()}");
    _model.isResizing = false;
    _model.resizeMode = '';
    notifyListeners();
  }

  // ==============================================
  // 🧹 ライフサイクル管理
  // ==============================================

  @override
  /// メモリ解放
  // OSの機能を使うときに必要
  void dispose() {
    logger.i('CameraViewModelのリソースを解放します');

    // CameraServiceのコントローラーのメモリ解放
    _cameraService.disposeCamera();
    // 継承した親クラス（ChangeNotifier）のdispose処理も実行
    // 内部にメモリが残るので必要
    super.dispose();

    logger.i('CameraViewModelのリソース解放が完了しました');
  }
}