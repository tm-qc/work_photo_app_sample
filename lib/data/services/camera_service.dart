import 'dart:io';// File（ファイル操作）を使うため
import 'dart:typed_data';// Uint8List（バイト配列）を使うため
import 'package:flutter/material.dart';// Offset、Size を使うため
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';// ギャラリー保存用
import 'package:image/image.dart' as img;// 画像合成ライブラリ
import 'package:path/path.dart' as path;// ファイルパス操作用
import 'package:path_provider/path_provider.dart';// アプリフォルダ取得用
import 'package:permission_handler/permission_handler.dart';// スマホ権限管理用
import '../../utils/global_logger.dart';

/// カメラの初期化・制御・撮影を担当するサービスクラス
///
/// 【利用想定】
/// ViewModelから呼び出される
/// UIロジック（Widget描画）は含まず、カメラ関連の純粋なビジネスロジックのみを担当
class CameraService {

  // ==============================================
  // 📱 プライベートプロパティ
  // ==============================================

  /// カメラコントローラーの実体
  /// 外部からは直接アクセスさせず、メソッド経由でコントロール
  CameraController? _controller;

  /// カメラ初期化処理のFuture
  /// 初期化完了を待機するためのFutureを保持
  Future<void>? _initializeControllerFuture;

  // ==============================================
  // 📱 パブリックゲッター
  // ==============================================

  /// カメラコントローラーを取得（読み取り専用）
  /// ViewModelやScreenから参照する際に使用
  // 例：CameraPreview(cameraService.controller) でプレビュー表示
  CameraController? get controller => _controller;

  /// カメラ初期化Futureを取得（読み取り専用）
  /// FutureBuilderで初期化完了を待つ際に使用
  ///
  //　外部からinitializeFutureという名前でアクセスされたら、_initializeControllerFutureの値を返すゲッター
  Future<void>? get initializeFuture => _initializeControllerFuture;

  /// カメラが初期化済みかを判定
  /// UI表示の制御やエラー回避に使用
  // 例：if (cameraService.isInitialized) { /* 撮影処理 */ }
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  // ==============================================
  // 🔧 カメラ初期化・終了処理
  // ==============================================

  /// カメラの初期化を実行
  ///
  /// ViewModel.initializeCamera() から呼ばれる
  ///
  /// 【引数】
  /// [camera]: 使用するカメラ（前面/背面）
  /// [resolutionPreset]: 画質設定（デフォルト: medium）
  ///
  /// 【戻り値】
  /// Future<void>: 初期化完了を示すFuture
  Future<void> initializeCamera(CameraDescription camera) async {
    try {
      // 既存のコントローラーがあれば解放
      await disposeCamera();

      // 新しいコントローラーを作成
      // カメラデバイスと解像度を指定してコントローラー生成
      _controller = CameraController(
        camera,
        // 解像度設定
        // Galaxy SC-42A(2020年のlowスマホ) では medium/high で発熱シャットダウン
        // 
        // TODO: 解像度は将来的に設定できめれるようにする？何が一番シンプルなコードでユーザビリティが良いか・・
        // 
        // 理想は
        // 1.自動で機種から判定でデフォルトの画質を決定
        // 2.機種により最高解像度を制限
        // 3.ユーザーがその選択肢で選べるようにする
        // 
        // 解像度が高いとメモリ消費が増え発熱で落ちるので、この設定が必要
        // 機種のスペック判定はAndroid OSのAPIレベルで行うのが一般的？
        // 汎用的、安定的な判定方法は要調査
        ResolutionPreset.low,
      );

      // カメラとの接続・初期化を実行
      // この処理は時間がかかるため非同期で実行
      // initialize：CameraControllerのメソッドでcameraパッケージが提供するカメラ初期化メソッド
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

  /// カメラリソースの解放
  ///
  /// メモリリークの防止
  ///
  /// 【呼び出し】
  /// - 画面終了時（ViewModel.dispose()から）
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

  /// 写真を撮影
  ///
  /// 【呼び出し元】
  /// ViewModel.takePicture() から呼ばれる
  ///
  /// 【戻り値】
  /// Future<XFile>: 撮影された画像ファイル
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
      // takePicture(): CameraパッケージのCameraControllerのメソッド。カメラから写真を撮影する
      final XFile image = await _controller!.takePicture();

      logger.i('写真撮影が完了しました: ${image.path}');
      return image;

    } catch (e) {
      logger.e('写真撮影に失敗しました: $e');
      rethrow;
    }
  }

  // ==============================================
  // 📸 撮影合成保存
  // ==============================================


  Future<String?> compositeAndSaveToGallery({
    required String cameraImagePath,
    required Uint8List blackboardImageData,
    required Offset blackboardPosition,
    required Size blackboardSize,
    required Size previewSize,
  }) async {
    try {
      logger.i('ギャラリー保存を開始');

      // 1. 権限チェック（Galaxy A21対応）
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          logger.e('ストレージ権限が拒否されました');
          return null;
        }
      }

      // 2. 既存のロジックで画像合成
      final img.Image? compositeImage = await _compositeImages(
        cameraImagePath: cameraImagePath,
        blackboardImageData: blackboardImageData,
        blackboardPosition: blackboardPosition,
        blackboardSize: blackboardSize,
        previewSize: previewSize,
      );

      if (compositeImage == null) {
        logger.e('画像合成に失敗');
        return null;
      }

      // 3. 一時ファイルに保存
      final String tempPath = await _saveTempImage(compositeImage);

      // 4. ギャラリーに保存（galパッケージ）
      await Gal.putImage(tempPath);
      
      logger.i('ギャラリー保存完了: $tempPath');
      return tempPath;

    } catch (e) {
      logger.e('ギャラリー保存エラー: $e');
      return null;
    }
  }

  // 🔧 NEW: 既存ロジックを使った画像合成（プライベートメソッド）
  Future<img.Image?> _compositeImages({
    required String cameraImagePath,
    required Uint8List blackboardImageData,
    required Offset blackboardPosition,
    required Size blackboardSize,
    required Size previewSize,
  }) async {
    try {
      // 撮影画像を読み込み
      final File cameraImageFile = File(cameraImagePath);
      final Uint8List cameraImageBytes = await cameraImageFile.readAsBytes();
      final img.Image? cameraImage = img.decodeImage(cameraImageBytes);
      
      if (cameraImage == null) return null;

      // 黒板画像を読み込み
      final img.Image? blackboardImage = img.decodePng(blackboardImageData);
      if (blackboardImage == null) return null;

      // 座標変換（既存ロジック）
      final double scaleX = cameraImage.width / previewSize.width;
      final double scaleY = cameraImage.height / previewSize.height;
      
      final int realX = (blackboardPosition.dx * scaleX).round();
      final int realY = (blackboardPosition.dy * scaleY).round();
      final int realWidth = (blackboardSize.width * scaleX).round();
      final int realHeight = (blackboardSize.height * scaleY).round();

      // 黒板リサイズ
      final img.Image resizedBlackboard = img.copyResize(
        blackboardImage,
        width: realWidth,
        height: realHeight,
      );

      // 画像合成
      return img.compositeImage(
        cameraImage,
        resizedBlackboard,
        dstX: realX,
        dstY: realY,
      );

    } catch (e) {
      logger.e('画像合成エラー: $e');
      return null;
    }
  }

  Future<String> _saveTempImage(img.Image compositeImage) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String fileName = 'photo_$timestamp.jpg';
    final String filePath = path.join(tempDir.path, fileName);

    final File outputFile = File(filePath);
    await outputFile.writeAsBytes(img.encodeJpg(compositeImage, quality: 90));

    return filePath;
  }

  // ==============================================
  // 🔧 ユーティリティメソッド
  // ==============================================

  /// カメラの使用可能性チェック
  ///
  /// 【用途】
  /// UI表示前にカメラが利用可能かを確認
  /// エラー画面の表示判定など
  ///
  /// 【戻り値】
  /// bool: true=利用可能, false=利用不可
  // ※25/06/06 時点未使用
  bool isAvailable() {
    return _controller != null && isInitialized;
  }

  /// カメラの状態情報を取得
  ///
  /// 【用途】
  /// デバッグ情報の表示
  /// トラブルシューティング
  ///
  /// 【戻り値】
  /// Map<String, dynamic>: カメラの状態情報
  /// ※25/06/06 時点未使用
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