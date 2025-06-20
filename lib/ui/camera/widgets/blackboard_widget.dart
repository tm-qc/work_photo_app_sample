// lib/ui/camera/widgets/blackboard_interactive_widget.dart
import 'package:flutter/material.dart';
import '../view_model/camera_view_model.dart';
import 'blackboard_setting_value_display_widget.dart';

/// カメラプレビューの黒板本体Widget
// - 黒板の設定値を表示するBlackboardSettingValueDisplayWidgetを読込
// - 黒板のドラッグ・リサイズ操作を行うなどインタラクティブ機能を参照する

// =======================================
// 🎯 メイン：黒板 + リサイズハンドル
// =======================================
/// 黒板のドラッグ・リサイズ操作を担当するWidget
///
/// 【使用方法】
/// BlackboardWidget(
///   viewModel: _viewModel,
///   parentContext: context,
/// )
class BlackboardWidget extends StatelessWidget {
  /// カメラ画面のViewModel（操作を委譲）
  final CameraViewModel viewModel;

  /// 親画面のContext（座標変換に必要）
  final BuildContext parentContext;

  /// カメラプレビューの画面サイズ
  final Size takePictureScreenSize;

  /// コンストラクタ
  const BlackboardWidget({
    // 呼び出し元のsuper.keyを継承してる
    super.key,
    required this.viewModel,
    required this.parentContext,
    required this.takePictureScreenSize,
  });

  /// カメラプレビュー上の黒板本体のWidgetをbuild
  @override
  Widget build(BuildContext context) {
    return Positioned(
      // 📍 位置制御：ViewModelの状態を参照
      left: viewModel.isInitialPosition ? 0 : viewModel.blackboardPosition.dx,
      top: viewModel.isInitialPosition ? null : viewModel.blackboardPosition.dy,
      bottom: viewModel.isInitialPosition ? 0 : null, // 初期位置では下端固定
      child: Stack(
        // 四隅のハンドルが黒板の外に出るため、はみ出しを許可
        clipBehavior: Clip.none, 
        children: [
          // ===============================
          // 📱 黒板本体
          // ===============================
          GestureDetector(
            behavior: HitTestBehavior.opaque, // タッチ検出を確実にする

            // ドラッグ開始：contextを渡す必要があるため明示的記述
            onPanStart: (DragStartDetails details) {
              viewModel.onPanStart(details, parentContext);
            },

            // ドラッグ更新：引数がそのまま渡せるが、明示的記述で統一
            onPanUpdate: (DragUpdateDetails details) {
              viewModel.onPanUpdate(details);
            },

            // ドラッグ終了：引数がそのまま渡せるが、明示的記述で統一
            onPanEnd: (DragEndDetails details) {
              viewModel.onPanEnd(details);
            },
            // RepaintBoundaryは、親ウィジェットの更新による不要な再描画から分離するウィジェット
            // Widgetの描画をキャプチャするための境界を定義します＝黒板をキャプチャー
            // 参考：https://flutter.salon/widget/repaintboundary/
            // 
            // TODO:撮影画像と黒板をキャプチャーする機能はあるがこれは黒板をキャプチャーだっけ？
            // GlobalKeyは RepaintBoundary に付ける必要があるので、Containerから出しました
            child: RepaintBoundary(
              // 重要：ViewModelからGlobalKeyを取得
              // key:これがないとドラッグの初動で黒板が下にずれる
              key: viewModel.blackboardKey,
              child: Container(
                // width,heightがないと四隅ドラッグの拡大縮小のサイズが黒板に反映しない
                width: viewModel.blackboardSize.width,
                height: viewModel.blackboardSize.height,

                decoration: BoxDecoration(
                  // 操作中の視覚的フィードバック
                  border: viewModel.isResizing || viewModel.isDragging
                      ? Border.all(color: Colors.blue, width: 4)
                      : null,
                ),

                // 黒板の設定値を表示するWidget
                // - ViewModel経由で保存された設定値を取得して表示
                child: BlackboardSettingValueDisplayWidget(
                  projectName: viewModel.projectName,   // 事業名
                  siteName: viewModel.siteName,         // 現場名
                  workTypeName: viewModel.workTypeName, // 作業種
                  forestUnit: viewModel.forestUnit,     // 林小班
                ),
              ),
            ),
          ),

          // ===============================
          // 🔧 四隅のリサイズハンドル
          // ===============================
          _buildCornerHandle('topLeft'),     // 左上
          _buildCornerHandle('topRight'),    // 右上
          _buildCornerHandle('bottomLeft'),  // 左下
          _buildCornerHandle('bottomRight'), // 右下
        ],
      ),
    );
  }

  /// 四隅のリサイズハンドルを作成するメソッド
  ///
  /// 【引数】
  /// [corner] どの角か（'topLeft', 'topRight', 'bottomLeft', 'bottomRight'）
  ///
  /// 【戻り値】
  /// Widget: 角丸配置済みのハンドルWidget
  ///
  // Widgetは「画面に表示される全ての部品の基底クラス」「何らかのUI部品を返すメソッド」という意味になるので、UIを形成するメソッドの場合に戻り値の型としてWidgetをつける
  Widget _buildCornerHandle(String corner) {

    // double型なら小数点も使える滑らかな位置指定が可能
    // 
    // finalよりconstを使う理由は？
    // constはコンパイル時に値が決定する定数で、パフォーマンスが向上します
    // 値も固定値なので constを使います
    const double cornerPosition = -10; // 角の位置を示す変数（初期値）
    // ハンドルのサイズを定義
    // TODO:ハンドルサイズが28以下になるとドラッグ移動が先に反応して、操作感が落ちてしまう印象が強くなる
    //      28でも操作感はもっと良くしたいと感じるが・・どうしようか検討中
    const double handleSize = 28.0; // ハンドルのサイズ

    return Positioned(
      // 角の位置に応じてtop/bottom、left/rightを設定
      top: corner.contains('top') ? cornerPosition : null,     // 上側の角なら上端からcornerPosition
      bottom: corner.contains('bottom') ? cornerPosition : null, // 下側の角なら下端からcornerPosition
      left: corner.contains('Left') ? cornerPosition : null,   // 左側の角なら左端からcornerPosition
      right: corner.contains('Right') ? cornerPosition : null, // 右側の角なら右端からcornerPosition

      child: GestureDetector(
        
        // リサイズ開始
        onPanStart: (DragStartDetails details) {
          viewModel.onCornerDragStart(corner, details);
        },

        // リサイズ更新
        onPanUpdate: (DragUpdateDetails details) {
          viewModel.onCornerDragUpdate(details, takePictureScreenSize);
        },

        // リサイズ終了
        onPanEnd: (DragEndDetails details) {
          viewModel.onCornerDragEnd();
        },

        // ハンドルの見た目
        // 
        child: Container(
          width: handleSize,
          height: handleSize,
          decoration: BoxDecoration(
            color: Colors.blue,                          // 🔵 青い色
            border: Border.all(color: Colors.white, width: 2), // 白い境界線
            borderRadius: BorderRadius.circular(12),      // 角丸
          ),
        ),
      ),
    );
  }
}