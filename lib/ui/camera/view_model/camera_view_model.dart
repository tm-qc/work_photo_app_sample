import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../domain/models/camera_model.dart';
import '../../../data/services/camera_service.dart';
import '../../../data/services/blackboard_service.dart';
import '../../../utils/global_logger.dart';

/// カメラ画面のViewModel（ChangeNotifier）
///
/// 【役割】
/// - CameraServiceとBlackboardServiceの統合管理
/// - UIからの操作を受け取りServiceに委譲
/// - ModelとServiceの状態をUIに通知（ChangeNotifier経由）
/// - ライフサイクル管理（初期化・終了処理）
///
/// 【利用想定】
/// Screen側でChangeNotifierProviderを使ってこのViewModelを管理
/// UIの状態変更は全てこのViewModelを通して実行
///
/// 【ChangeNotifierとは】
/// Flutter標準の状態管理クラス
/// notifyListeners()により、リスナー登録されたWidgetに変更を自動通知
class CameraViewModel extends ChangeNotifier {

  // ==============================================
  // 🔧 サービス依存関係
  // ==============================================

  /// カメラ操作を担当するサービス
  /// カメラの初期化・撮影・リソース管理を委譲
  final CameraService _cameraService;

  /// 黒板操作を担当するサービス
  /// 黒板の移動・リサイズ・座標計算を委譲
  final BlackboardService _blackboardService;

  /// 現在の状態を保持するModel
  /// UIはこのModelの値を参照して描画
  CameraModel _state;

  // ==============================================
  // 🏗️ コンストラクタ・初期化
  // ==============================================

  /// ViewModelのコンストラクタ
  ///
  /// 【引数】
  /// [cameraService]: カメラ操作サービス（通常は外部から注入）
  /// [blackboardService]: 黒板操作サービス（通常は外部から注入）
  ///
  /// 【初期化】
  /// 空のCameraModelで状態管理を開始
  CameraViewModel({
    CameraService? cameraService,
    BlackboardService? blackboardService,
  })  : _cameraService = cameraService ?? CameraService(),
        _blackboardService = blackboardService ?? BlackboardService(),
        _state = CameraModel();

  // ==============================================
  // 📊 状態アクセサ（Getter）
  // ==============================================

  /// 現在の状態を取得（読み取り専用）
  ///
  /// 【利用想定】
  /// Screen側でViewModelの状態を参照
  /// 例：viewModel.state.blackboardPosition
  CameraModel get state => _state;

  /// カメラコントローラーを取得（読み取り専用）
  ///
  /// 【利用想定】
  /// CameraPreview(viewModel.controller) でプレビュー表示
  CameraController? get controller => _state.controller;

  /// カメラ初期化Futureを取得（読み取り専用）
  ///
  /// 【利用想定】
  /// FutureBuilder<void>(future: viewModel.initializeFuture, ...)
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
  ///
  /// 【処理の流れ】
  /// 1. CameraServiceでカメラ初期化
  /// 2. 初期化結果をModelに反映
  /// 3. UI側に状態変更を通知（notifyListeners）
  ///
  /// 【呼び出し元】
  /// Screen.initState() から呼ばれる
  ///
  /// 【引数】
  /// [camera]: 使用するカメラデバイス
  /// [resolutionPreset]: 画質設定（オプション）
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
  ///
  /// 【処理の流れ】
  /// 1. CameraServiceで撮影実行
  /// 2. 撮影データ（XFile）を返却
  ///
  /// 【呼び出し元】
  /// Screen.FloatingActionButton.onPressed から呼ばれる
  ///
  /// 【戻り値】
  /// Future<XFile>: 撮影された画像ファイル
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
  ///
  /// 【用途】
  /// UI表示前にカメラが利用可能かを確認
  /// 撮影ボタンの有効/無効切り替えなど
  ///
  /// 【戻り値】
  /// bool: true=利用可能, false=利用不可
  bool isCameraAvailable() {
    return _cameraService.isAvailable();
  }

  // ==============================================
  // 🎯 黒板移動関連の操作メソッド
  // ==============================================

  /// 黒板移動の開始処理
  ///
  /// 【処理の流れ】
  /// 1. BlackboardServiceで移動開始処理
  /// 2. Model状態を更新（isDragging = true など）
  /// 3. UI側に状態変更を通知
  ///
  /// 【呼び出し元】
  /// Screen.GestureDetector.onPanStart から呼ばれる
  ///
  /// 【引数】
  /// [details]: ドラッグ開始時の詳細情報
  /// [context]: 座標変換に必要なコンテキスト
  void onPanStart(DragStartDetails details, BuildContext context) {
    // BlackboardServiceに移動開始処理を委譲
    _blackboardService.startDragging(
      _state,
      details,
      context,
      _state.blackboardKey,
    );

    // UI更新をトリガー
    notifyListeners();
  }

  /// 黒板移動の更新処理
  ///
  /// 【処理の流れ】
  /// 1. BlackboardServiceで位置計算
  /// 2. Model状態を更新（blackboardPosition など）
  /// 3. UI側に状態変更を通知
  ///
  /// 【呼び出し元】
  /// Screen.GestureDetector.onPanUpdate から呼ばれる
  void onPanUpdate(DragUpdateDetails details) {
    // BlackboardServiceに移動更新処理を委譲
    _blackboardService.updateDragging(_state, details);

    // UI更新をトリガー
    notifyListeners();
  }

  /// 黒板移動の終了処理
  ///
  /// 【処理の流れ】
  /// 1. BlackboardServiceで移動終了処理
  /// 2. Model状態を更新（isDragging = false など）
  /// 3. UI側に状態変更を通知
  ///
  /// 【呼び出し元】
  /// Screen.GestureDetector.onPanEnd から呼ばれる
  void onPanEnd(DragEndDetails details) {
    // BlackboardServiceに移動終了処理を委譲
    _blackboardService.endDragging(_state);

    // UI更新をトリガー
    notifyListeners();
  }

  // ==============================================
  // 📏 黒板リサイズ関連の操作メソッド
  // ==============================================

  /// 黒板リサイズの開始処理
  ///
  /// 【処理の流れ】
  /// 1. BlackboardServiceでリサイズ開始処理
  /// 2. Model状態を更新（isResizing = true, resizeMode など）
  /// 3. UI側に状態変更を通知
  ///
  /// 【呼び出し元】
  /// Screen.CornerHandle.onPanStart から呼ばれる
  ///
  /// 【引数】
  /// [corner]: 操作する角（'topLeft', 'topRight', 'bottomLeft', 'bottomRight'）
  /// [details]: ドラッグ開始時の詳細情報
  void onCornerDragStart(String corner, DragStartDetails details) {
    print("🔧 ViewModel: リサイズ開始 - $corner");

    // BlackboardServiceにリサイズ開始処理を委譲
    _blackboardService.startResize(_state, corner, details);

    // UI更新をトリガー
    notifyListeners();
  }

  /// 黒板リサイズの更新処理
  ///
  /// 【処理の流れ】
  /// 1. BlackboardServiceでサイズ・位置計算
  /// 2. Model状態を更新（blackboardWidth, blackboardHeight, blackboardPosition など）
  /// 3. UI側に状態変更を通知
  ///
  /// 【呼び出し元】
  /// Screen.CornerHandle.onPanUpdate から呼ばれる
  void onCornerDragUpdate(DragUpdateDetails details) {
    // BlackboardServiceにリサイズ更新処理を委譲
    _blackboardService.updateResize(_state, details);

    // UI更新をトリガー
    notifyListeners();
  }

  /// 黒板リサイズの終了処理
  ///
  /// 【処理の流れ】
  /// 1. BlackboardServiceでリサイズ終了処理
  /// 2. Model状態を更新（isResizing = false, resizeMode = '' など）
  /// 3. UI側に状態変更を通知
  ///
  /// 【呼び出し元】
  /// Screen.CornerHandle.onPanEnd から呼ばれる
  void onCornerDragEnd() {
    print("🔧 ViewModel: リサイズ終了");

    // BlackboardServiceにリサイズ終了処理を委譲
    _blackboardService.endResize(_state);

    // UI更新をトリガー
    notifyListeners();
  }

  // ==============================================
  // 🔧 ユーティリティ・状態管理メソッド
  // ==============================================

  /// 黒板の境界チェック・位置調整
  ///
  /// 【用途】
  /// 黒板が画面外に出ないよう位置を調整
  /// 画面サイズ変更時などに呼び出し
  ///
  /// 【引数】
  /// [screenSize]: 現在の画面サイズ
  void constrainBlackboardPosition(Size screenSize) {
    final constrainedPosition = _blackboardService.constrainPosition(_state, screenSize);
    _state.blackboardPosition = constrainedPosition;
    notifyListeners();
  }

  /// デバッグ情報の取得
  ///
  /// 【用途】
  /// 開発時のトラブルシューティング
  /// デバッグ画面での状態表示
  ///
  /// 【戻り値】
  /// Map<String, dynamic>: 統合された状態情報
  Map<String, dynamic> getDebugInfo() {
    return {
      'camera': _cameraService.getCameraStatus(),
      'blackboard': _blackboardService.getBlackboardStatus(_state),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ==============================================
  // 🧹 ライフサイクル管理
  // ==============================================

  /// リソースの解放処理
  ///
  /// 【処理内容】
  /// 1. CameraServiceのリソース解放
  /// 2. Model内のリソース解放
  /// 3. ChangeNotifierのリソース解放
  /// 4. メモリリークの防止
  ///
  /// 【呼び出し元】
  /// Screen.dispose() から呼ばれる
  ///
  /// 【重要】
  /// ChangeNotifierのdisposeをオーバーライドし、
  /// 親クラスのdisposeも必ず呼び出す
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