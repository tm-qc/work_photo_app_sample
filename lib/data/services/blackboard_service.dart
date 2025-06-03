import 'package:flutter/material.dart';
import '../../domain/models/camera_model.dart';

/// 黒板の位置・サイズ・操作を管理するサービスクラス
///
/// 【役割】
/// - 黒板の移動処理（初期位置 → 絶対座標変換）
/// - 黒板のリサイズ処理（四隅ハンドル操作）
/// - ドラッグ操作の状態管理
/// - 座標計算とバリデーション
///
/// 【利用想定】
/// ViewModelから呼び出され、黒板操作の全てのロジックを担当
/// UIの描画は行わず、純粋な計算・状態管理のみ
class BlackboardService {

  // ==============================================
  // 🎯 移動処理（ドラッグ）
  // ==============================================

  /// 黒板の移動開始処理
  ///
  /// 【処理内容】
  /// 1. 初期位置（bottom固定）から絶対座標への変換
  /// 2. ドラッグ開始時の座標を記録
  /// 3. 移動状態フラグをON
  ///
  /// 【呼び出し元】
  /// ViewModel.onPanStart() から呼ばれる
  ///
  /// 【引数】
  /// [model]: カメラ画面の状態を保持するモデル
  /// [details]: タッチ開始時の詳細情報
  /// [context]: 座標変換に必要なコンテキスト
  /// [blackboardKey]: 黒板の位置・サイズ取得用のKey
  void startDragging(
      CameraModel model,
      DragStartDetails details,
      BuildContext context,
      GlobalKey blackboardKey,
      ) {
    // リサイズ中は移動処理をスキップ
    if (model.isResizing) return;

    print("🎯 移動開始: focalPoint=${details.globalPosition}");

    // 初期位置（bottom: 0）から絶対座標への変換処理
    if (model.isInitialPosition) {
      _convertFromInitialPosition(model, context, blackboardKey, details.globalPosition);
    } else {
      // 既に絶対座標配置済みの場合の通常移動開始
      _startNormalDragging(model, details.globalPosition);
    }
  }

  /// 初期位置から絶対座標への変換処理
  ///
  /// 【背景】
  /// 黒板は最初「bottom: 0」で画面下端に固定されているが、
  /// ドラッグ開始と同時に「left/top」による絶対座標配置に切り替える必要がある
  ///
  /// 【処理手順】
  /// 1. GlobalKeyから現在の黒板位置を取得
  /// 2. 画面全体での絶対座標に変換
  /// 3. 絶対座標配置モードに切り替え
  ///
  /// 【🚨 重要】
  /// 元のコードと全く同じロジックを使用（localToGlobalをそのまま使用）
  void _convertFromInitialPosition(
      CameraModel model,
      BuildContext context,
      GlobalKey blackboardKey,
      Offset globalPosition,
      ) {
    // 黒板ウィジェットの描画情報を取得
    final RenderBox? renderBox = blackboardKey.currentContext?.findRenderObject() as RenderBox?;
    // 画面全体（TakePictureScreen）の描画情報を取得
    final RenderBox screenBox = context.findRenderObject() as RenderBox;

    if (renderBox != null) {
      // 🔧 元のコードと全く同じ座標変換を使用
      // localToGlobal：黒板のローカル座標（Offset.zero = 左上）をancestor（ここでは画面全体screenBox）から見た絶対座標を取得
      final blackboardPosition = renderBox.localToGlobal(Offset.zero, ancestor: screenBox);
      print("🔧 初期位置変換: bottom配置 → 絶対座標${blackboardPosition}");

      // 🔧 元のコードと全く同じ状態更新
      model.isInitialPosition = false;
      model.blackboardPosition = blackboardPosition;
      model.dragStartPosition = globalPosition;
      model.dragStartBlackboardPosition = blackboardPosition;
      model.isDragging = true;

    } else {
      // 🔧 元のコードと全く同じフォールバック処理
      final size = screenBox.size;
      final fallbackPosition = Offset(0, size.height - model.blackboardHeight);

      print("⚠️ フォールバック: ${fallbackPosition}");

      model.isInitialPosition = false;
      model.blackboardPosition = fallbackPosition;
      model.dragStartPosition = globalPosition;
      model.dragStartBlackboardPosition = fallbackPosition;
      model.isDragging = true;
    }
  }

  /// 通常の移動開始処理（既に絶対座標配置済みの場合）
  void _startNormalDragging(CameraModel model, Offset globalPosition) {
    model.isDragging = true;
    model.dragStartPosition = globalPosition;
    model.dragStartBlackboardPosition = model.blackboardPosition;
  }

  /// 黒板の移動更新処理
  ///
  /// 【処理内容】
  /// 指の移動量を計算し、黒板の新しい位置を決定
  ///
  /// 【計算式】
  /// 新しい位置 = 開始時の黒板位置 + 指の移動量
  /// 指の移動量 = 現在の指の位置 - 開始時の指の位置
  ///
  /// 【呼び出し元】
  /// ViewModel.onPanUpdate() から呼ばれる
  void updateDragging(CameraModel model, DragUpdateDetails details) {
    // 移動中でない、または、リサイズ中の場合はスキップ
    if (!model.isDragging || model.isResizing) return;

    // 🔧 元のコードと同じ計算式を使用
    // 指の移動量を計算
    // details.globalPosition: 現在のタッチ位置（グローバル座標）
    // model.dragStartPosition: ドラッグ開始時のタッチ位置
    final deltaMovement = details.globalPosition - model.dragStartPosition;

    // 新しい黒板位置を計算
    // 「開始時の黒板位置」+「指がどれだけ動いたか」=「新しい黒板位置」
    final newPosition = model.dragStartBlackboardPosition + deltaMovement;

    model.blackboardPosition = newPosition;
  }

  /// 黒板の移動終了処理
  ///
  /// 【処理内容】
  /// 移動状態フラグをOFFにして移動完了
  void endDragging(CameraModel model) {
    print("🎯 移動終了: 最終位置=${model.blackboardPosition}");
    model.isDragging = false;
  }

  // ==============================================
  // 📏 リサイズ処理（四隅ハンドル）
  // ==============================================

  /// リサイズ開始処理
  ///
  /// 【処理内容】
  /// 1. リサイズモードON
  /// 2. どの角を操作中かを記録
  /// 3. リサイズ開始時の状態を保存
  ///
  /// 【引数】
  /// [model]: カメラ画面の状態モデル
  /// [corner]: 操作する角（'topLeft', 'topRight', 'bottomLeft', 'bottomRight'）
  /// [details]: タッチ開始時の詳細情報
  void startResize(CameraModel model, String corner, DragStartDetails details) {
    print("🔧 リサイズ開始: $corner");

    model.isResizing = true;
    model.resizeMode = corner;
    model.dragStartPosition = details.globalPosition;
    model.dragStartSize = Size(model.blackboardWidth, model.blackboardHeight);
    model.dragStartBlackboardPosition = model.blackboardPosition;
  }

  /// リサイズ更新処理
  ///
  /// 【重要な座標系の理解】
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
  void updateResize(CameraModel model, DragUpdateDetails details) {
    if (!model.isResizing) return;

    // 指の移動量を計算
    final delta = details.globalPosition - model.dragStartPosition;

    // 角に応じたリサイズ処理
    switch (model.resizeMode) {
      case 'topLeft':
        _resizeTopLeft(model, delta);
        break;
      case 'topRight':
        _resizeTopRight(model, delta);
        break;
      case 'bottomLeft':
        _resizeBottomLeft(model, delta);
        break;
      case 'bottomRight':
        _resizeBottomRight(model, delta);
        break;
    }

    print("📏 リサイズ中: ${model.blackboardWidth.toInt()}x${model.blackboardHeight.toInt()}");
  }

  /// 左上角のリサイズ処理
  ///
  /// 【特徴】
  /// - 右下を固定点として拡大縮小
  /// - 左や上に引っ張ると大きくなる（逆方向の動き）
  /// - 位置調整が必要（固定点を維持するため）
  void _resizeTopLeft(CameraModel model, Offset delta) {
    // 幅の計算：左に引っ張ると幅が増加（delta.dxがマイナス）
    final newWidth = (model.dragStartSize.width - delta.dx).clamp(100.0, 400.0);
    // 高さの計算：上に引っ張ると高さが増加（delta.dyがマイナス）
    final newHeight = (model.dragStartSize.height - delta.dy).clamp(80.0, 300.0);

    model.blackboardWidth = newWidth;
    model.blackboardHeight = newHeight;

    // 位置調整：右下を固定点として維持
    model.blackboardPosition = Offset(
      model.dragStartBlackboardPosition.dx + (model.dragStartSize.width - newWidth),
      model.dragStartBlackboardPosition.dy + (model.dragStartSize.height - newHeight),
    );
  }

  /// 右上角のリサイズ処理
  ///
  /// 【特徴】
  /// - 左下を固定点として拡大縮小
  /// - Y座標のみ調整が必要
  void _resizeTopRight(CameraModel model, Offset delta) {
    // 幅の計算：右に引っ張ると幅が増加（delta.dxがプラス）
    final newWidth = (model.dragStartSize.width + delta.dx).clamp(100.0, 400.0);
    // 高さの計算：上に引っ張ると高さが増加（delta.dyがマイナス）
    final newHeight = (model.dragStartSize.height - delta.dy).clamp(80.0, 300.0);

    model.blackboardWidth = newWidth;
    model.blackboardHeight = newHeight;

    // 位置調整：Y座標のみ調整（左端を固定）
    model.blackboardPosition = Offset(
      model.dragStartBlackboardPosition.dx,
      model.dragStartBlackboardPosition.dy + (model.dragStartSize.height - newHeight),
    );
  }

  /// 左下角のリサイズ処理
  ///
  /// 【特徴】
  /// - 右上を固定点として拡大縮小
  /// - X座標のみ調整が必要
  void _resizeBottomLeft(CameraModel model, Offset delta) {
    // 幅の計算：左に引っ張ると幅が増加（delta.dxがマイナス）
    final newWidth = (model.dragStartSize.width - delta.dx).clamp(100.0, 400.0);
    // 高さの計算：下に引っ張ると高さが増加（delta.dyがプラス）
    final newHeight = (model.dragStartSize.height + delta.dy).clamp(80.0, 300.0);

    model.blackboardWidth = newWidth;
    model.blackboardHeight = newHeight;

    // 位置調整：X座標のみ調整（上端を固定）
    model.blackboardPosition = Offset(
      model.dragStartBlackboardPosition.dx + (model.dragStartSize.width - newWidth),
      model.dragStartBlackboardPosition.dy,
    );
  }

  /// 右下角のリサイズ処理
  ///
  /// 【特徴】
  /// - 左上を固定点として拡大縮小
  /// - 最もシンプル（位置調整不要）
  void _resizeBottomRight(CameraModel model, Offset delta) {
    // 幅の計算：右に引っ張ると幅が増加（delta.dxがプラス）
    model.blackboardWidth = (model.dragStartSize.width + delta.dx).clamp(100.0, 400.0);
    // 高さの計算：下に引っ張ると高さが増加（delta.dyがプラス）
    model.blackboardHeight = (model.dragStartSize.height + delta.dy).clamp(80.0, 300.0);
    // 位置調整は不要（左上を固定点とするため）
  }

  /// リサイズ終了処理
  ///
  /// 【処理内容】
  /// リサイズ状態フラグをOFFにしてリサイズ完了
  void endResize(CameraModel model) {
    print("🔧 リサイズ終了: ${model.blackboardWidth.toInt()}x${model.blackboardHeight.toInt()}");
    model.isResizing = false;
    model.resizeMode = '';
  }

  // ==============================================
  // 🔧 ユーティリティメソッド
  // ==============================================

  /// 黒板の境界チェック
  ///
  /// 【用途】
  /// 黒板が画面外に出ないよう位置を調整
  ///
  /// 【引数】
  /// [model]: カメラ画面の状態モデル
  /// [screenSize]: 画面のサイズ
  ///
  /// 【戻り値】
  /// Offset: 調整された位置
  Offset constrainPosition(CameraModel model, Size screenSize) {
    final x = model.blackboardPosition.dx.clamp(
      0.0,
      screenSize.width - model.blackboardWidth,
    );
    final y = model.blackboardPosition.dy.clamp(
      0.0,
      screenSize.height - model.blackboardHeight,
    );
    return Offset(x, y);
  }

  /// 黒板のサイズ制限チェック
  ///
  /// 【用途】
  /// 黒板のサイズが適切な範囲内かをチェック
  ///
  /// 【引数】
  /// [width]: チェックする幅
  /// [height]: チェックする高さ
  ///
  /// 【戻り値】
  /// Size: 制限適用後のサイズ
  Size constrainSize(double width, double height) {
    return Size(
      width.clamp(100.0, 400.0),
      height.clamp(80.0, 300.0),
    );
  }

  /// 黒板の状態情報を取得
  ///
  /// 【用途】
  /// デバッグ情報の表示
  /// 開発時のトラブルシューティング
  ///
  /// 【戻り値】
  /// Map<String, dynamic>: 黒板の状態情報
  Map<String, dynamic> getBlackboardStatus(CameraModel model) {
    return {
      'position': model.blackboardPosition,
      'size': Size(model.blackboardWidth, model.blackboardHeight),
      'isInitialPosition': model.isInitialPosition,
      'isDragging': model.isDragging,
      'isResizing': model.isResizing,
      'resizeMode': model.resizeMode,
    };
  }
}