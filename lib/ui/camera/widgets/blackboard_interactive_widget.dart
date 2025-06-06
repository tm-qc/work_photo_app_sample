// lib/ui/camera/widgets/blackboard_interactive_widget.dart
import 'package:flutter/material.dart';
import '../view_model/camera_view_model.dart';
import 'blackboard_widget.dart';

// =======================================
// 🎯 メイン：黒板 + リサイズハンドル
// =======================================
/// 黒板のドラッグ・リサイズ操作を担当するWidget
///
/// 【使用方法】
/// BlackboardInteractiveWidget(
///   viewModel: _viewModel,
///   parentContext: context,
/// )
class BlackboardInteractiveWidget extends StatelessWidget {
  /// カメラ画面のViewModel（操作を委譲）
  final CameraViewModel viewModel;

  /// 親画面のContext（座標変換に必要）
  final BuildContext parentContext;

  /// コンストラクタ
  const BlackboardInteractiveWidget({
    // 呼び出し元のsuper.keyを継承してる
    super.key,
    required this.viewModel,
    required this.parentContext,
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

            child: Container(
              // 重要：ViewModelからGlobalKeyを取得
              // key:これがないとドラッグの初動で黒板が下にずれる
              key: viewModel.blackboardKey,

              // width,heightがないと四隅ドラッグの拡大縮小のサイズが黒板に反映しない
              width: viewModel.blackboardSize.width,
              height: viewModel.blackboardSize.height,

              decoration: BoxDecoration(
                // 操作中の視覚的フィードバック
                border: viewModel.isResizing || viewModel.isDragging
                    ? Border.all(color: Colors.blue, width: 4)
                    : null,
              ),

              child: const BlackboardWidget(), // 実際の黒板コンテンツ
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
    return Positioned(
      // 角の位置に応じてtop/bottom、left/rightを設定
      top: corner.contains('top') ? -8 : null,     // 上側の角なら上端から-8px
      bottom: corner.contains('bottom') ? -8 : null, // 下側の角なら下端から-8px
      left: corner.contains('Left') ? -8 : null,   // 左側の角なら左端から-8px
      right: corner.contains('Right') ? -8 : null, // 右側の角なら右端から-8px

      child: GestureDetector(
        // リサイズ開始
        onPanStart: (DragStartDetails details) {
          viewModel.onCornerDragStart(corner, details);
        },

        // リサイズ更新
        onPanUpdate: (DragUpdateDetails details) {
          viewModel.onCornerDragUpdate(details);
        },

        // リサイズ終了
        onPanEnd: (DragEndDetails details) {
          viewModel.onCornerDragEnd();
        },

        // ハンドルの見た目
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.blue,                          // 🔵 青い色
            border: Border.all(color: Colors.white, width: 2), // 白い境界線
            borderRadius: BorderRadius.circular(8),      // 角丸
          ),
        ),
      ),
    );
  }
}