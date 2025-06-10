import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../view_model/camera_view_model.dart';
import '../../../utils/global_logger.dart';
import 'blackboard_interactive_widget.dart';
import 'blackboard_size_display.dart';
import 'display_picture_screen.dart';

/// カメラプレビューと黒板の表示・操作を行うメイン画面 StatefulWidget
class TakePictureScreen extends StatefulWidget {

  /// コンストラクタ
  /// camera という変数を外から必ず（required）受け取る
  // super.keyについて
  // 親Widget(継承元)から同時に同じ子Widgetを複数表示するときに、内部で処理、値を識別するために使われる
  // なお、以下の場合はScreenからkeyを渡さなくてもOK。その場合nullが渡る
  //
  // - Navigator.pushで新しい画面スタックに追加=同時に同じWidgetを複数表示にならない
  // - 一意性の問題が発生しない仕様
  const TakePictureScreen({super.key, required this.camera});

  // 利用するカメラ（前面カメラ or 背面カメラ）を外部から渡す
  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

/// カメラ画面の状態管理クラス（UI専用）
class TakePictureScreenState extends State<TakePictureScreen> {

  // ==============================================
  // 🎯 ViewModel管理
  // ==============================================

  /// カメラ操作のViewModel
  // ViewModel
  // - ビジネスロジック（Service）を参照し結果をScreenに渡す
  // - 状態管理はViewModelに定義する
  late CameraViewModel _viewModel;

  // ==============================================
  // 🏗️ ライフサイクル管理
  // ==============================================

  ///初期化メソッド
  @override
  void initState() {
    //親のinitStateをoverrideしてるので親も動かす
    super.initState();

    // ViewModelを初期化
    _viewModel = CameraViewModel();

    // ViewModelの状態変更を監視し変更があれば通知し変更をUIを更新するための定義（定型文）
    // ViewModelでChangeNotifierを継承してるから変更が検知できる
    _viewModel.addListener(_onViewModelChanged);

    // カメラ初期化をViewModelに委譲
    _initializeCamera();
  }

  /// メモリ解放
  // Widgetがoff=カメラが閉じた時に動く
  @override
  void dispose() {
    // ViewModelの監視を停止
    _viewModel.removeListener(_onViewModelChanged);
    // ViewModelのメモリ開放を動かす
    _viewModel.dispose();
    // 継承した親クラスのメモリに残るものを解放
    super.dispose();
  }

  /// ViewModelの状態変更時にUIを更新
  void _onViewModelChanged() {
    if (mounted) {  // 画面がまだ表示されている場合のみ更新
      setState(() {
        // ViewModelの状態が変更されたのでUIを再描画=初期化
      });
    }
  }

  /// カメラ初期化処理
  Future<void> _initializeCamera() async {
    try {
      // widget.camera
      // StatefulWidgetクラスのインスタンスを参照するプロパティ
      // 今回はclass TakePictureScreen extends StatefulWidgetのcameraを参照
      await _viewModel.initializeCamera(widget.camera);
    } catch (e) {
      // エラーログはViewModelで出力済み
      logger.e('画面でのカメラ初期化エラー: $e');
    }
  }


  // ==============================================
  // 🏗️ メインのUI構築（元のコードから完全移植）
  // ==============================================

  /// カメラプレビューメインをbuild
  @override
  Widget build(BuildContext context) {
    // 📱 Screen側でscreenSizeを取得
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('カメラプレビュー')),
      // 「body大枠にFutureBuilder = 非同期初期化が必要な画面」の定型パターン
      body: FutureBuilder<void>(
        // 🔧 重要：ViewModelからFutureを取得
        //
        // future
        // FutureBuilderで使うオプション。監視する非同期処理を指定
        // - ViewModelのinitializeFutureの状態変化のたびにbuilderが実行され、状態に応じたUIを描画(=builderが動く)
        // - initializeFutureはcamera使う際の決まりでパッケージの初期化をしてる
        //   (サービス、ビューモデルと根深いのでわかりづらいが結局これがサービスでされてるの理解でOK)
        future: _viewModel.initializeFuture,
        builder: (context, snapshot) {
          // 監視している非同期処理が完了したかどうかを判定
          if (snapshot.connectionState == ConnectionState.done) {
            // カメラ初期化完了：メインUIを表示
            // Stack:「Widgetを重ね合わせるためのレイアウトWidget」
            return Stack(
              children: [
                // =======================================
                // 🎥 背景：カメラプレビュー
                // =======================================
                // ViewModelからcontrollerを取得
                if (_viewModel.controller != null) CameraPreview(_viewModel.controller!),

                // デバッグ情報：現在の黒板のサイズ表示のWidget読みこみ
                BlackboardSizeDisplay(blackboardSize: _viewModel.blackboardSize),
                
                // 🎯 メイン：黒板 + リサイズハンドル
                BlackboardInteractiveWidget(
                  viewModel: _viewModel,
                  parentContext: context,
                  screenSize: screenSize,
                ),
              ],
            );
          } else if (snapshot.hasError) {
            // カメラ初期化エラー時の表示
            return const Center(
              child: Text('カメラの初期化に失敗しました'),
            );
          } else {
            // カメラ初期化中の表示
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),

      // =======================================
      // 📸 撮影ボタン（FloatingActionButton）
      // =======================================
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            // 撮影処理をViewModelに委譲
            final XFile image = await _viewModel.takePicture();

            // 画面遷移のみScreenが担当
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DisplayPictureScreen(imagePath: image.path),
                ),
              );
            }
          } catch (e) {
            logger.e('写真撮影に失敗しました: $e');
          }
        },
        child: const Icon(Icons.camera_alt), // カメラアイコン
      ),
    );
  }
}