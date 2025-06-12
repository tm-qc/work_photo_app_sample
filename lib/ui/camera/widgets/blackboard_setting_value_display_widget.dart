import 'package:flutter/material.dart';
import 'package:work_photo_app_sample/config/app_config.dart';

import 'blackboard_label.dart';
import 'blackboard_value.dart';

/// カメラプレビュー上の黒板に黒板の設定値を表示するWidget
// 
// ドラッグや拡大縮小の機能もあるので、
// lib\ui\camera\widgets\blackboard_interactive_widget.dart
// で初期サイズなども設定されて読み込まれてる

// 関数で書くか、クラス化するか？
//
// - 本体＝関数、パーツ＝クラス:一般的
// 　関数は「表示箇所が1つで、複雑な中身を含む場合」ときに採用するらしい
// - 両方クラスでもOK：クラスかすると無駄に長くなることもあるとのこと
// - 両方関数：あまりしないらしい。パーツの使い回し・引数管理が面倒になりやすいとのこと
//
// 今回最初はこうなっていた
// lib/ui/camera/widgets/blackboard_widget.dart：黒板本体で関数で作成
// lib/ui/camera/widgets/blackboard_label.dart：黒板本体のパーツだがクラスで作成
//
// 個人的に・・
// 両方クラスの方がなぜ片方関数？みたいにならない
// メインの本体のほうが親でパーツより関係性は上なのに関数>クラスの関係になっておりしっくりこない
// みたいな気がする
//
// → 考えた結果全部クラスにしました
// 　やった結果そんなに手間増えないし、呼び出すときにcontextを引数に渡さなくてよかった

class BlackboardSettingValueDisplayWidget extends StatelessWidget {
  // ==============================================
  // 📋 黒板の設定値を受け取るプロパティ
  // ==============================================
  
  /// 事業名
  final String projectName;
  
  /// 現場名 
  final String siteName;
  
  /// 作業種の表示名（"作業前"、"作業中"、"作業後"など）
  final String workTypeName;
  
  /// 林小班
  final String forestUnit;

  // ==============================================
  // 🏗️ コンストラクタ
  // ==============================================

  /// BlackboardWidgetのコンストラクタ
  /// 
  /// 【使用例】
  /// BlackboardWidget(
  ///   projectName: viewModel.projectName,
  ///   siteName: viewModel.siteName,  
  ///   workTypeName: viewModel.workTypeName,
  ///   forestUnit: viewModel.forestUnit,
  /// )
  const BlackboardSettingValueDisplayWidget({
    super.key,
    required this.projectName,
    required this.siteName,
    required this.workTypeName,
    required this.forestUnit,
  });

  // BuildContext は画面上の位置・状態を持つcontextを使うのに必要
  @override
  Widget build(BuildContext context) {
    // MediaQuery.of
    // 今の画面サイズや表示情報（幅、高さ、文字サイズなど）を取得するための仕組み
    // MediaQuery.of(context) から取得できる情報はsize.height	画面の縦の長さなど他にもある
    // ※今回ここでは不要メモで残す
    // final Size previewSize = MediaQuery.of(context).size;

    // Container：黒板の大枠で最上の親要素で見た目（枠・色・余白）などを調整するための大箱
    return Container(
      // decoration：「見た目（色・線・影・角丸など）」専用。サイズ指定はしない
      // decoration は Container に使うプロパティ（背景、枠線、角丸など）
      decoration: BoxDecoration(
        color: const Color(0xFF2E5E4E), // ダークグリーン背景
        // top, bottom, left, rightに線を引く
        border: Border.all(color: Colors.white, width: 1),
      ),
      // child：1つのWidgetだけ渡すときに使うプロパティ
      // ※ContainerやPaddingなど、1つだけの子Widgetを持てる設計になっているWidgetで使
      // Column：中の要素を縦並びにする
      child: Column(
        // （今回はColumnが）中身に必要な高さだけ取るように設定
        mainAxisSize: MainAxisSize.min,
        // Container（親の枠）の幅横幅いっぱいに子要素を広げる
        crossAxisAlignment: CrossAxisAlignment.stretch,


        // children：複数の子Widgetを指定する場合に使う。childで書いたらエラーにあるので直せばOK
        // ※Row や Column は、複数のWidgetを受け取る前提で作られているので、常に children を使います。
        children: [
          // 1行目：事業名
          // Rowでラベルと値を横並びにして1行として扱う
          //
          // ContainerとExpandedで構成されるが、共通のレイアウトでそろえる場合は
          // 小さなWidgetに切り出して使うのが一般的らしい
          // Row：要素を横並びにする
          Row(
            children: [
              // 事業名ラベル
              // パーツで共通化済み
              // widthは初期値60だが引数で設定も可能
              const BlackboardLabel(text: '事業名'),
              // 事業名の値
              BlackboardValue(
                text: projectName.isNotEmpty ? projectName : AppConfig.notSetText, 
                showRightBorder:false
              ),
            ],
          ),

          // 2行目：現場名と林小班を横に並べる
          Row(
            children: [
              // 現場名ラベル
              const BlackboardLabel(text: '現場名'),
              // 値
              BlackboardValue(
                text: siteName.isNotEmpty ? siteName : AppConfig.notSetText
              ),
              // 林小班ラベル
              const BlackboardLabel(text: '林小班'),
              // 値
              BlackboardValue(
                text: forestUnit.isNotEmpty ? forestUnit : AppConfig.notSetText, 
                showRightBorder:false),
            ],
          ),

          // 3行目：作業種の設定値
          // 作業種だけラベルなし、値の枠の大きさが特殊なので共通パーツBlackboardValueは使わない
          // Expanded 自体が「空間を均等に割る役割」
          Expanded(
            child: Align(
              child: Text(
                workTypeName.isNotEmpty ? workTypeName : AppConfig.notSetText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            )
          ),
        ],
      ),
    );
  }

}




