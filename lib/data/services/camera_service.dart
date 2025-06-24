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
        // 解像度+比率設定
        // Galaxy SC-42A(2020年のAndroidTM 10（AndroidTM 11対応）) では medium/high で発熱シャットダウン
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
        // 
        // CameraパッケージのResolutionPreset 一覧
        // https://pub.dev/documentation/flutter_better_camera/latest/camera/ResolutionPreset.html
        // 
        // プリセット      iOS          Android      比率(iOS)   比率(Android)
        // ----------------------------------------------------------------
        // low           352x288      320x240      11:9        4:3
        // medium        640x480      720x480      4:3         3:2  
        // high          1280x720     1280x720     16:9        16:9
        // veryHigh      1920x1080    1920x1080    16:9        16:9
        // ultraHigh     3840x2160    3840x2160    16:9        16:9
        // max           最高解像度    最高解像度    機種依存     機種依存
        // 
        // カメラプレビューの比率
        // low:360:480 = 3:4 (縦長)
        // high:360:640 = 9:16 
        // 
        // 現在の設定
        // ResolutionPreset.low: 320x240 (4:3) ← 横長
        // プレビュー: 360(w)x480(h) (3:4) ← 縦長
        // → 比率が逆のため黒板が歪む→縦横は自動で会うので関係ないっぽい
        // 
        // TODO:パフォーマンス
        // 参考にしてる電子小黒板のアプリではAndroid OS 5.0以上がサポートでカメラプレビューが1280*960(4:3)でサクサク動いて、画像保存も問題ありません
        // FLutterでは、なぜlowで320x240じゃないとGalaxy SC-42A(2020年のAndroidTM 10（AndroidTM 11対応）)ですら、熱で動かなくなるかわからない不明。
        // エミュレータだからというのもある？
        ResolutionPreset.high,
      );

      // カメラとの接続・初期化を実行
      // この処理は時間がかかるため非同期で実行
      // initialize：CameraControllerのメソッドでcameraパッケージが提供するカメラ初期化メソッド
      _initializeControllerFuture = _controller!.initialize();

      // 初期化完了まで待機
      await _initializeControllerFuture!;

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
      }
    } catch (e) {
      logger.e('カメラリソースの解放に失敗しました: $e');
    }
  }

  // ==============================================
  // 📸 撮影処理
  // ==============================================

  /// 写真を撮影
  /// 純粋な撮影画像を取得するメソッド
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

      return image;

    } catch (e) {
      logger.e('写真撮影に失敗しました: $e');
      rethrow;
    }
  }

  // ==============================================
  // 📸 撮影合成保存
  // ==============================================


  /// 撮影画像と黒板を合成してギャラリーに保存
  /// 
  /// 【引数】
  /// cameraImagePath: 撮影した写真のファイルパス
  /// blackboardImageData: 黒板のスクリーンショット画像（PNG形式）
  /// blackboardPosition: 黒板を配置する座標（カメラプレビュー上での位置）
  /// blackboardSize: 黒板のサイズ（カメラプレビュー上でのサイズ）  
  /// cameraPreviewSize: カメラプレビューのサイズ（座標変換の基準）
  /// 
  /// 【戻り値】
  /// String?: 保存成功時はファイルパス、失敗時はnull
  Future<String?> compositeAndSaveToGallery({
    required String cameraImagePath,
    required Uint8List blackboardImageData,
    required Offset blackboardPosition,
    required Size blackboardSize,
    required Size cameraPreviewSize,
  }) async {
    try {
      // 1. 権限チェック
      // Android 13以降はWRITE_EXTERNAL_STORAGE権限が不要になったが、古い機種の互換性のために残す
      // TODO:仮想エミュレータで権限拒否で保存できないのはなぜ？
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
        cameraPreviewSize: cameraPreviewSize,
      );

      if (compositeImage == null) {
        logger.e('画像合成に失敗');
        return null;
      }

      // 3. 一時ファイルに保存
      final String tempPath = await _saveTempImage(compositeImage);

      // 4. ギャラリーに保存（galパッケージ）
      await Gal.putImage(tempPath);
      return tempPath;

    } catch (e) {
      logger.e('ギャラリー保存エラー: $e');
      return null;
    }
  }

  ///  画像合成処理の本体
  /// 
  /// 【なぜ画像の計算、リサイズが必要か？】
  /// 
  /// スマホで表示されるカメラプレビューと撮影画像は比率は同じで見た目違和感がないが、サイズが違うため
  /// 
  /// - プレビュー: 画面サイズに合わせて表示＝比率を保つので見た目は違和感ない
  /// - 撮影画像: 設定解像度で保存＝比率を保つので見た目は違和感ない(おそらく実際はカメラプレビューより大きくなってる)
  /// 
  /// 【引数】
  /// cameraImagePath: 撮影した写真のファイルパス
  /// blackboardImageData: 黒板のPNG画像データ（Uint8List）
  /// blackboardPosition: 黒板の配置座標（カメラプレビュー上での位置）
  /// blackboardSize: 黒板のサイズ（カメラプレビュー上でのサイズ）
  /// cameraPreviewSize: カメラプレビューのサイズ（座標変換の基準）
  /// 
  /// 【戻り値】
  /// img.Image?: 合成済み画像、失敗時はnull
  Future<img.Image?> _compositeImages({
    required String cameraImagePath,
    required Uint8List blackboardImageData,
    required Offset blackboardPosition,
    required Size blackboardSize,
    required Size cameraPreviewSize,
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

      /// 座標変換（既存ロジック）

      // スケール(拡大縮小率)を計算
      // 
      // スマホで表示されるカメラプレビューと撮影画像は比率は同じで見た目は違和感がないが、
      // 実際のサイズが違うので、この計算でスケール(拡大縮小率)を算出し、これを基準に調整しないといけない
      // ※カメラプレビューより撮影画像の方が大きくなってるので「撮影画像のサイズ / カメラプレビューサイズ」で基準値になるスケール(拡大縮小率)を計算
      // ※ここは写真撮影画面全体じゃなくてcameraPreviewSizeを基準に計算しないといけない
      final double scaleX = cameraImage.width / cameraPreviewSize.width;
      final double scaleY = cameraImage.height / cameraPreviewSize.height;
      
      // 黒板の画像を実際の比率に合わせて調整
      
      // ポジション
      // ※スケールで調整しないと位置がずれる
      // ※黒板の位置を算出
      final int blackboardRealX = (blackboardPosition.dx * scaleX).round();
      final int blackboardRealY = (blackboardPosition.dy * scaleY).round();
      // 黒板画像のサイズを算出
      // WidthとHeightをそれぞれのスケールで調整
      final int blackboardRealWidth = (blackboardSize.width * scaleX).round();
      final int blackboardRealHeight = (blackboardSize.height * scaleY).round();

      // 黒板リサイズを実行
      final img.Image resizedBlackboard = img.copyResize(
        blackboardImage,
        width: blackboardRealWidth,
        height: blackboardRealHeight,
      );

      // 撮影画像と黒板画像を合成(img.ImageのcompositeImageメソッドを使用)
      return img.compositeImage(
        cameraImage,
        resizedBlackboard,
        dstX: blackboardRealX,
        dstY: blackboardRealY,
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