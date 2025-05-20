import 'package:flutter/material.dart';

// 関数で書くか、クラス化するか？
//
// - 本体＝関数、パーツ＝クラス:一般的
// 　関数は「表示箇所が1つで、複雑な中身を含む場合」ときに採用するらしい
// - 両方クラスでもOK：クラスかすると無駄に長くなることもあるとのこと
// - 両方関数：あまりしないらしい。パーツの使い回し・引数管理が面倒になりやすいとのこと
//
// 今回こうなってる
// lib/ui/camera/widgets/blackboard_screen.dart：黒板本体で関数で作成
// lib/ui/camera/widgets/blackboard_label.dart：黒板本体のパーツだがクラスで作成
//
// 個人的に・・
// 両方クラスの方がなぜ片方関数？みたいにならない
// メインの本体のほうが親でパーツより関係性は上なのに関数>クラスの関係になっておりしっくりこない
// みたいな気がする

// BuildContext は画面上の位置・状態を持つcontextを使うのに必要
Widget buildBlackboard(BuildContext context) {
  // MediaQuery.of
  // 今の画面サイズや表示情報（幅、高さ、文字サイズなど）を取得するための仕組み
  // MediaQuery.of(context) から取得できる情報はsize.height	画面の縦の長さなど他にもある
  //
  // なぜここに定義？
  // context は Widget のビルド時に渡されるので、この関数の先頭で取得するのが正解
  final Size previewSize = MediaQuery.of(context).size;

  // Container：黒板の大枠で最上の親要素で見た目（枠・色・余白）などを調整するための大箱
  return Container(
    height: previewSize.height * 0.2,// 黒板の高さを画面の20％に設定(子から参照するのに必要)
    width: previewSize.width * 0.5, // 黒板の幅をプレビューの幅＝画面の幅の半分に設定
    // decoration：「見た目（色・線・影・角丸など）」専用。サイズ指定はしない
    // decoration は Container に使うプロパティ（背景、枠線、角丸など）
    decoration: BoxDecoration(
      color: const Color(0xFF2E5E4E), // ダークグリーン背景
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

      // TODO:黒板の行単位の高さなどの設定については出来なかったので保留
      // 一旦事業名の行だけ高さを指定しようとしたが、FlutterのUI構築の仕組みが予想以上に意味がわからなかった
      // 何かしらの親要素追加が必要+ネスト深まる+閉じタグつけにくい+何が必要なのか不規則で独自性がすごい
      // などで法則性がなく、予想以上にわからずに詰みました。
      // 他の事終わってまた余裕あったらする

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
            // Container：見た目を整えるための箱
            Container(
              width: 60,
              // padding指定だけだが、メソッド使い分けが必要みたいです
              // メソッド、引数名が長いし覚えにくい・・・
              //
              // EdgeInsets.all(8)：全方向に同じ余白	全部まとめて
              // EdgeInsets.symmetric(horizontal: 4, vertical: 6)：上下と左右で分けたいとき
              // EdgeInsets.only(left: 4, top: 2)：個別に設定したいとき
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.white, width: 1),
                  bottom: BorderSide(color: Colors.white, width: 1),
                ),
              ),
              child: const Text(
                '事業名',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            // 事業名の値
            // Expanded：Containerで使ってない幅＝RowやColumn内で、残りのスペースを自動で広がるように使う指示するメソッド
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 1),
                  ),
                ),
                child: const Text(
                  '事業名の設定値',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),

        // 2行目：現場名と林小班を横に並べる
        // IntrinsicHeight( // 高さを内容に合わせる
        //   child: Row(
        //     crossAxisAlignment: CrossAxisAlignment.stretch,
        //     children: [
        //       // 現場名ラベル
        //       Container(
        //         width: 60,
        //         padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
        //         decoration: const BoxDecoration(
        //           border: Border(
        //             right: BorderSide(color: Colors.white, width: 1),
        //             bottom: BorderSide(color: Colors.white, width: 1),
        //           ),
        //         ),
        //         child: const Text(
        //           '現場名',
        //           style: TextStyle(color: Colors.white, fontSize: 12),
        //         ),
        //       ),
        //       // 現場名の値
        //       Expanded(
        //         flex: 3,
        //         child: Container(
        //           padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
        //           decoration: const BoxDecoration(
        //             border: Border(
        //               right: BorderSide(color: Colors.white, width: 1),
        //               bottom: BorderSide(color: Colors.white, width: 1),
        //             ),
        //           ),
        //           child: const Text(
        //             '現場名の設定値',
        //             style: TextStyle(color: Colors.white, fontSize: 12),
        //           ),
        //         ),
        //       ),
        //       // 林小班ラベル
        //       Container(
        //         width: 60,
        //         padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
        //         decoration: const BoxDecoration(
        //           border: Border(
        //             right: BorderSide(color: Colors.white, width: 1),
        //             bottom: BorderSide(color: Colors.white, width: 1),
        //           ),
        //         ),
        //         child: const Text(
        //           '林小班',
        //           style: TextStyle(color: Colors.white, fontSize: 12),
        //         ),
        //       ),
        //       // 林小班の値
        //       Expanded(
        //         flex: 3,
        //         child: Container(
        //           padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
        //           decoration: const BoxDecoration(
        //             border: Border(
        //               bottom: BorderSide(color: Colors.white, width: 1),
        //             ),
        //           ),
        //           child: const Text(
        //             '林小班の設定値',
        //             style: TextStyle(color: Colors.white, fontSize: 12),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),

        // 3行目：作業種の設定値
        // Container(
        //   padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        //   alignment: Alignment.center,
        //   child: const Text(
        //     '作業種の設定値',
        //     style: TextStyle(
        //       color: Colors.white,
        //       fontSize: 16,
        //       fontWeight: FontWeight.bold,
        //     ),
        //   ),
        // ),
      ],
    ),
  );
}


