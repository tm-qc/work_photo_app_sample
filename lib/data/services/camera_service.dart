import 'package:camera/camera.dart';
import '../../utils/global_logger.dart';

// カメラの初期化・制御・撮影を担当するサービスクラス
//
// 【役割】
// - カメラコントローラーの初期化
// - カメラの起動・終了
// - 写真撮影処理
// - エラーハンドリング
//
// 【利用想定】
// ViewModelから呼び出され、カメラ関連の全ての操作を担当
// UIロジック（Widget描画）は含まず、純粋なビジネスロジックのみ
class CameraService {

  // ==============================================
  // 📱 プライベートプロパティ
  // ==============================================

  // カメラコントローラーの実体
  // 外部からは直接アクセスさせず、メソッド経由でコントロール
  CameraController? _controller;

  // カメラ初期化処理のFuture
  // 初期化完了を待機するためのFutureを保持
  Future<void>? _initializeControllerFuture;

  // ==============================================
  // 📱 パブリックゲッター
  // ==============================================

  // カメラコントローラーを取得（読み取り専用）
  // ViewModelやScreenから参照する際に使用
  // 例：CameraPreview(cameraService.controller) でプレビュー表示
  // ★これももともとないけどなぜ必要なの？ファイル分けたから？なぜ_のprivateと併用してる？
  CameraController? get controller => _controller;

  // カメラ初期化Futureを取得（読み取り専用）
  // FutureBuilderで初期化完了を待つ際に使用
  // 例：FutureBuilder<void>(future: cameraService.initializeFuture, ...)
  // ★これももともとないけどなぜ必要なの？ファイル分けたから？なぜ_のprivateと併用してる？
  Future<void>? get initializeFuture => _initializeControllerFuture;

  // カメラが初期化済みかを判定
  // UI表示の制御やエラー回避に使用
  // 例：if (cameraService.isInitialized) { /* 撮影処理 */ }
  // ★これももともとないけどなぜ必要なの？ファイル分けたから？なぜ_のprivateと併用してる？
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  // ==============================================
  // 🔧 カメラ初期化・終了処理
  // ==============================================

  // カメラの初期化を実行
  //
  // 【処理内容】
  // 1. CameraControllerを作成
  // 2. 指定されたカメラで初期化
  // 3. エラーハンドリング
  //
  // 【呼び出し元】
  // ViewModel.initializeCamera() から呼ばれる
  //
  // 【引数】
  // [camera]: 使用するカメラ（前面/背面）
  // [resolutionPreset]: 画質設定（デフォルト: medium）
  //
  // 【戻り値】
  // Future<void>: 初期化完了を示すFuture
  Future<void> initializeCamera(
      CameraDescription camera,
      {ResolutionPreset resolutionPreset = ResolutionPreset.medium}
      ) async {
    try {
      // 既存のコントローラーがあれば解放
      await disposeCamera();

      // 新しいコントローラーを作成
      // カメラデバイスと解像度を指定してコントローラー生成
      _controller = CameraController(
        camera,
        resolutionPreset,
      );

      // カメラとの接続・初期化を実行
      // この処理は時間がかかるため非同期で実行
      _initializeControllerFuture = _controller!.initialize();

      // 初期化完了まで待機
      await _initializeControllerFuture!;

      logger.i('カメラの初期化が完了しました');

    } catch (e) {
      // 初期化エラーをログ出力
      logger.e('カメラの初期化に失敗しました: $e');

      // エラー状態のFutureを設定
      // これによりFutureBuilder側でsnapshot.hasErrorがtrueになる
      _initializeControllerFuture = Future.error(e);

      // エラーを再スロー（呼び出し元でキャッチ可能）
      rethrow;
    }
  }

  // カメラリソースの解放
  //
  // 【処理内容】
  // - カメラコントローラーの解放
  // - メモリリークの防止
  //
  // 【呼び出しタイミング】
  // - 画面終了時（ViewModel.dispose()から）
  // - 別のカメラに切り替える前
  // - アプリ終了時
  //
  // ★もともとのこのコードとは何がちがう？
  // void dispose() {
  //   // Widgetが破棄されるときに、カメラコントローラーも解放
  //   _controller.dispose();
  //   super.dispose();
  // }
  Future<void> disposeCamera() async {
    try {
      // コントローラーが存在する場合のみ解放
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
        _initializeControllerFuture = null;
        logger.i('カメラリソースを解放しました');
      }
    } catch (e) {
      logger.e('カメラリソースの解放に失敗しました: $e');
    }
  }

  // ==============================================
  // 📸 撮影処理
  // ==============================================

  // 写真を撮影
  //
  // 【処理内容】
  // 1. カメラ初期化確認
  // 2. 写真撮影実行
  // 3. 撮影データ（XFile）を返却
  //
  // 【呼び出し元】
  // ViewModel.takePicture() から呼ばれる
  //
  // 【戻り値】
  // Future<XFile>: 撮影された画像ファイル
  //
  // 【例外】
  // - カメラ未初期化の場合: StateError
  // - 撮影失敗の場合: CameraException
  Future<XFile> takePicture() async {
    try {
      // カメラの初期化確認
      if (!isInitialized) {
        throw StateError('カメラが初期化されていません');
      }

      // 初期化処理の完了を待機（安全のため）
      if (_initializeControllerFuture != null) {
        await _initializeControllerFuture!;
      }

      // 写真撮影を実行
      // XFile: 撮影された画像の一時ファイル情報
      final XFile image = await _controller!.takePicture();

      // ★もとのこれは別ファイルにかく？？
      // if (context.mounted) {
      //   // 撮影した写真を表示する画面へ遷移
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) =>
      //           DisplayPictureScreen(imagePath: image.path),
      //     ),
      //   );
      // }

      logger.i('写真撮影が完了しました: ${image.path}');
      return image;

    } catch (e) {
      logger.e('写真撮影に失敗しました: $e');
      rethrow;
    }
  }

  // ==============================================
  // 🔧 ユーティリティメソッド
  // ==============================================

  // カメラの使用可能性チェック
  //
  // 【用途】
  // UI表示前にカメラが利用可能かを確認
  // エラー画面の表示判定など
  //
  // 【戻り値】
  // bool: true=利用可能, false=利用不可
  bool isAvailable() {
    return _controller != null && isInitialized;
  }

  // カメラの状態情報を取得
  //
  // 【用途】
  // デバッグ情報の表示
  // トラブルシューティング
  //
  // 【戻り値】
  // Map<String, dynamic>: カメラの状態情報
  // ★なぜわざわざ作成した？？
  Map<String, dynamic> getCameraStatus() {
    return {
      'hasController': _controller != null,
      'isInitialized': isInitialized,
      'isRecordingVideo': _controller?.value.isRecordingVideo ?? false,
      'isTakingPicture': _controller?.value.isTakingPicture ?? false,
      'hasError': _controller?.value.hasError ?? false,
      'errorDescription': _controller?.value.errorDescription,
    };
  }
}