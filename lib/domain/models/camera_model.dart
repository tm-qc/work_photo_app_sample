import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// カメラ画面の状態を管理する値をもつためのModelクラス
class CameraModel {
  // ==============================================
  // 📱 カメラ関連のプロパティ
  // ==============================================

  /// カメラを制御するためのコントローラー
  /// カメラの初期化、プレビュー表示、撮影処理を担当
  CameraController? controller;

  /// カメラ初期化の非同期処理のFuture
  /// カメラ初期化完了を待つためのFuture型プロパティ
  Future<void>? initializeControllerFuture;

  // ==============================================
  // 🎯 黒板の位置・サイズ管理用プロパティ
  // ==============================================

  /// 初期位置（bottom: 0）かどうかを判定するフラグ
  /// trueの場合は画面下端に固定、falseの場合は絶対座標で配置
  bool isInitialPosition = true;

  /// 黒板の位置を保持（初期は左下付近の座標）
  /// offset:Stackの中での相対位置。今回はカメラプレビュー内になる。Stack内のPositionedで使われてる
  Offset blackboardPosition = const Offset(0, 0);

  /// 黒板のサイズを取得するためのGlobalKey
  /// ウィジェットの位置やサイズを取得する際に使用
  final GlobalKey blackboardKey = GlobalKey();

  // ==============================================
  // 📏 リサイズ機能用のプロパティ
  // ==============================================

  /// 黒板の幅（ピクセル単位）(黒板初期サイズ)
  /// リサイズ操作で変更される
  double blackboardWidth = 200.0;

  /// 黒板の高さ（ピクセル単位）(黒板初期サイズ)
  /// リサイズ操作で変更される
  double blackboardHeight = 150.0;

  /// 移動中フラグ
  /// 黒板をドラッグで移動している最中はtrue
  bool isDragging = false;

  /// リサイズ中フラグ
  /// 四隅のハンドルでリサイズしている最中はtrue
  bool isResizing = false;

  /// リサイズモード識別子
  /// どの角をリサイズ中かを示す（'topLeft', 'topRight', 'bottomLeft', 'bottomRight'）
  String resizeMode = '';

  // ==============================================
  // 🎯 ドラッグ操作時の初期値保存用プロパティ
  // ==============================================

  /// ドラッグ開始時のタッチ座標
  /// ドラッグ操作の移動量計算に使用
  Offset dragStartPosition = Offset.zero;

  /// ドラッグ開始時の黒板サイズ
  /// リサイズ操作時の基準サイズとして使用
  Size dragStartSize = Size.zero;

  /// ドラッグ開始時の黒板座標
  /// ドラッグ操作時の基準位置として使用
  Offset dragStartBlackboardPosition = Offset.zero;

  // ==============================================
  // 🔧 コンストラクタ
  // ==============================================

  /// CameraModelのコンストラクタ
  /// 必要に応じて初期値を設定
  CameraModel();
}