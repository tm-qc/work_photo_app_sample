import 'dart:typed_data';// Uint8List（バイト配列）を使うため
import 'dart:ui' as ui;// ui.Image（画像データ）を使うため

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';// RenderRepaintBoundary を使うため
import 'package:geolocator/geolocator.dart';
import 'package:work_photo_app_sample/config/app_config.dart';
import 'package:work_photo_app_sample/data/services/blackboard_setting_service.dart';
import 'package:work_photo_app_sample/data/services/gps.dart';
import 'package:work_photo_app_sample/domain/models/blackboard_setting_model.dart';
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

  /// 黒板設定の読み込みを担当するサービス
  final BlackboardSettingService _blackboardSettingService;

  /// GPS取得サービス
  final GpsService _gpsService = GpsService();

  // ==============================================
  // 🏗️ コンストラクタ・初期化
  // ==============================================

  /// ViewModelのコンストラクタ
  CameraViewModel({
    CameraService? cameraService,
    BlackboardSettingService? blackboardSettingService,
  })  : _cameraService = cameraService ?? CameraService(),
        _model = CameraModel(),
        _blackboardSettingService = blackboardSettingService ?? BlackboardSettingService();

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

  /// 黒板の現在サイズを取得(初期サイズ)
  Size get blackboardSize => Size(_model.blackboardWidth, _model.blackboardHeight);

  /// 初期位置かどうかを取得
  bool get isInitialPosition => _model.isInitialPosition;

  /// ドラッグ中かどうかを取得
  bool get isDragging => _model.isDragging;

  /// リサイズ中かどうかを取得
  bool get isResizing => _model.isResizing;

  /// 黒板のGlobalKeyを取得
  GlobalKey get blackboardKey => _model.blackboardKey;

  /// カメラプレビューのGlobalKeyを取得
  GlobalKey get cameraPreviewKey => _model.cameraPreviewKey;


  // ==============================================
  // 📋 黒板設定値アクセサ
  // ==============================================

  /// 事業名を取得
  String get projectName => _model.projectName;

  /// 現場名を取得
  String get siteName => _model.siteName;

  /// 作業種のキーを取得
  int get workTypeKey => _model.workTypeKey;

  /// 作業種の表示名を取得
  // 保存された数字の設定値をBlackboardSettingModel.workTypeOptionsで文字に変換して取得してる
  String get workTypeName => BlackboardSettingModel.workTypeOptions[_model.workTypeKey] ?? AppConfig.notSetText;

  /// 林小班を取得
  String get forestUnit => _model.forestUnit;

  // ==============================================
  // 📷 撮影画像取得変換系のメソッド
  // ==============================================

  /// 黒板Widgetを取得し画像データに変換
  // 
  // 【何をしているか】
  // 1. 画面に表示されている黒板Widget（あなたが見ている黒板）
  // 2. それをスクリーンショットして画像データに変換
  // 3. 後で撮影画像と合成するために使用
  
  Future<Uint8List?> captureBlackboardAsImage() async {
    try {
      // 1. 画面に表示中の黒板Widgetを特定
      // GlobalKey(_model.blackboardKey)を使って、現在のBuildContextから黒板WidgetのRenderObjectを取得
      // 
      // 1. RepaintBoundary(key: key)           // Widget作成(今回はlib\ui\camera\widgets\blackboard_widget.dartで使われてる)
      // 2. key.currentContext                  // Context取得(ContextはWidgetの位置や状態を表す)
      // 3. .findRenderObject()                 // RenderObject取得(今回は黒板Widgetの描画情報)
      // 4. as RenderRepaintBoundary?           // 型変換
      final RenderRepaintBoundary? boundary = 
          _model.blackboardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        logger.e('黒板Widgetが見つかりません');
        return null;
      }

      // 2. 黒板Widget → 画像データに変換（スクリーンショット）
      // pixelRatioは画質（解像度）を決める。アスペクト比は変わらない
      // 
      // TODO:不確かなので後で確認。画質がきれいで重くなるだけでサイズは変わらない気がする
      // 
      // 例）
      // pixelRatio: 1.0 → 生成画像：200x150ピクセル
      // pixelRatio: 2.0 → 生成画像：400x300ピクセル
      // pixelRatio: 3.0 → 生成画像：600x450ピクセル 
      // 
      // サイズpx(大きさ):画像の幅と高さに基づいた総ピクセル数
      // 解像度ppi(綺麗さ):画像の印刷時に1インチあたりに割り当てられる画像ピクセル数で、1インチあたりのピクセル数（ppi）で表されます。
      //　　　　　したがって、1インチあたりの画像のピクセル数が多いほど、解像度は高くなります。
      //　　　　　また、高解像度の画像を使用すると、印刷出力の品質が向上します
      // 
      // ※別件補足：DPI（Dots Per Inch）は、主にプリンターやスキャナーなどの解像度を表す単位
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      
      // 3. 画像データ → PNG形式のバイト配列に変換
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      // 4. 他のメソッドで使いやすい形式で返す
      final Uint8List? result = byteData?.buffer.asUint8List();
      return result;

    } catch (e) {
      logger.e('黒板スクリーンショットに失敗: $e');
      return null;
    }
  }

  /// 黒板つき写真を撮影し合成・保存メソッドを参照して実行
  // 
  // 【処理の流れ】
  // 1. 通常のカメラ撮影
  // 2. 黒板をスクリーンショット
  // 3. 2つの画像を合成
  // 4. 端末に保存
  Future<String?> takePictureWithBlackboard() async {
    try {
      // 1. 通常のカメラ撮影（黒板は映ってない純粋な撮影画像を取得する）
      final XFile cameraImage = await _cameraService.takePicture();

      // 2. GPS情報を取得
      Position? gpsPosition = await _gpsService.getCurrentPosition();

      if (gpsPosition != null) {
        logger.i('GPS付き撮影: ${_gpsService.formatPosition(gpsPosition)}');
      } else {
        logger.w('GPS取得失敗。GPS情報なしで撮影を続行します。');
      }
      
      // 2. 黒板をスクリーンショット
      final Uint8List? blackboardData = await captureBlackboardAsImage();
      if (blackboardData == null) {
        logger.e('黒板データの取得に失敗');
        return null;
      }

      // 3.カメラプレビューのRenderBoxを取得する
      // 　モデルに定義したカメラプレビューのグローバルキーを利用し取得
      final RenderBox? cameraPreview = 
          _model.cameraPreviewKey.currentContext?.findRenderObject() as RenderBox?;
      // カメラプレビューのサイズオブジェクトを取得
      final Size cameraPreviewSize = cameraPreview?.size ?? Size.zero;

      // 4. カメラサービスで画像合成・保存をする
      // - cameraImage.path: 撮影したカメラ画像のパス
      //   "/data/user/0/com.work_photo_app_sample.work_photo_app_sample/cache/CAP3069506080177115524.jpg"
      // 
      // - blackboardData: 黒板のスクリーンショットデータ
      // - _model.blackboardPosition: 黒板の位置（画面上の座標）
      // - Size(_model.blackboardWidth, _model.blackboardHeight): 黒板のサイズ（幅と高さ）(拡大縮小あればちゃんとその値になってる)
      // cameraPreviewSize: カメラプレビューのサイズ（撮影画像のアスペクト比に合わせるため）
      final String? savedPath = await _cameraService.compositeAndSaveToGallery(
        cameraImagePath: cameraImage.path,
        blackboardImageData: blackboardData,
        blackboardPosition: _model.blackboardPosition,
        blackboardSize: Size(_model.blackboardWidth, _model.blackboardHeight),
        cameraPreviewSize: cameraPreviewSize,
      );

      if (savedPath == null) {
        throw Exception('画像の保存に失敗しました');
      }
      
      return savedPath;

    } catch (e) {
      logger.e('撮影・保存エラー: $e');
      return null;
    }
  }

  // ==============================================
  // 📱 カメラ関連の操作メソッド
  // ==============================================

  /// カメラの初期化
  Future<void> initializeCamera(CameraDescription camera) async {
    try {
      // CameraServiceに初期化を委譲
      await Future.wait([
        _cameraService.initializeCamera(camera),  // カメラ初期化
        _loadBlackboardSettings(),                // 黒板設定読み込み
      ]);

      // 初期化成功：Modelにカメラ情報を設定
      _model.controller = _cameraService.controller!;
      _model.initializeControllerFuture = _cameraService.initializeFuture!;

      // UI更新を通知
      // モデルの状態が変わるタイミングは通知が必要
      notifyListeners();
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

  // ==============================================
  // 📋 黒板設定値読み込みメソッド（NEW!）
  // ==============================================

  /// 黒板設定値を読み込む
  Future<void> _loadBlackboardSettings() async {
    try {
      // BlackboardSettingServiceから設定値を取得
      // TODO:todo_01 そもそも黒板設定のサービスをカメラプレビューの黒板の値の取得に使うべきか？
      final settingsData = await _blackboardSettingService.load();

      // Modelに設定値を反映
      _model.projectName = settingsData[BlackboardSettingModel.projectKey] ?? '';
      _model.siteName = settingsData[BlackboardSettingModel.siteKey] ?? '';
      // TODO:todo_01
      _model.workTypeKey = settingsData[BlackboardSettingModel.workTypeKey] ?? '';
      _model.forestUnit = settingsData[BlackboardSettingModel.forestKey] ?? '';
      logger.d('読み込んだ値: 事業名=${_model.projectName}, 現場名=${_model.siteName}, 作業種=${_model.workTypeKey}, 林小班=${_model.forestUnit}');

    } catch (e) {
      logger.e('黒板設定値の読み込みに失敗しました: $e');
      
      // エラー時はデフォルト値を設定
      _model.projectName = '';
      _model.siteName = '';
      _model.workTypeKey = BlackboardSettingModel.defaultWorkTypeKey;
      _model.forestUnit = '';
    }
  }

  /// 黒板設定値を手動で再読み込み（必要に応じて使用）
  Future<void> reloadBlackboardSettings() async {
    await _loadBlackboardSettings();
    notifyListeners(); // UI更新を通知
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
  void onCornerDragUpdate(DragUpdateDetails details, Size takePictureScreenSize) {
    if (!_model.isResizing) return;

    // 現在のタッチ位置 - 開始時のタッチ位置 = 移動量
    final delta = details.globalPosition - _model.dragStartPosition;

    // 最低サイズ制限を適用
    // clamp(min, max)でサイズを制限
    // 縦横比:初期サイズ 150(h)÷200(w) = 0.75 = 3:4:一般的っぽい
    const double minWidth = 200.0; // 最小幅(初期値と同じ)
    const double minHeight = 150.0; // 最小高さ(初期値と同じ)
    final double maxWidth = takePictureScreenSize.width; // 最大幅(写真撮影画面全体の幅)
    const double maxHeight = 300.0; // 最大高さ(初期値の倍)

    // 🔧 元のコードと同じswitch文による角別処理
    switch (_model.resizeMode) {
      case 'topLeft':
        final newWidth = (_model.dragStartSize.width - delta.dx).clamp(minWidth, maxWidth);
        final newHeight = (_model.dragStartSize.height - delta.dy).clamp(minHeight, maxHeight);
        _model.blackboardWidth = newWidth;
        _model.blackboardHeight = newHeight;
        _model.blackboardPosition = Offset(
          _model.dragStartBlackboardPosition.dx + (_model.dragStartSize.width - newWidth),
          _model.dragStartBlackboardPosition.dy + (_model.dragStartSize.height - newHeight),
        );
        break;

      case 'topRight':
        final newWidth = (_model.dragStartSize.width + delta.dx).clamp(minWidth, maxWidth);
        final newHeight = (_model.dragStartSize.height - delta.dy).clamp(minHeight, maxHeight);
        _model.blackboardWidth = newWidth;
        _model.blackboardHeight = newHeight;
        _model.blackboardPosition = Offset(
          _model.dragStartBlackboardPosition.dx,
          _model.dragStartBlackboardPosition.dy + (_model.dragStartSize.height - newHeight),
        );
        break;

      case 'bottomLeft':
        final newWidth = (_model.dragStartSize.width - delta.dx).clamp(minWidth, maxWidth);
        final newHeight = (_model.dragStartSize.height + delta.dy).clamp(minHeight, maxHeight);
        _model.blackboardWidth = newWidth;
        _model.blackboardHeight = newHeight;
        _model.blackboardPosition = Offset(
          _model.dragStartBlackboardPosition.dx + (_model.dragStartSize.width - newWidth),
          _model.dragStartBlackboardPosition.dy,
        );
        break;

      case 'bottomRight':
        _model.blackboardWidth = (_model.dragStartSize.width + delta.dx).clamp(minWidth, maxWidth);
        _model.blackboardHeight = (_model.dragStartSize.height + delta.dy).clamp(minHeight, maxHeight);
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
    // CameraServiceのコントローラーのメモリ解放
    _cameraService.disposeCamera();
    // 継承した親クラス（ChangeNotifier）のdispose処理も実行
    // 内部にメモリが残るので必要
    super.dispose();
  }
}