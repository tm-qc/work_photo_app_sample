import 'package:flutter/material.dart';
import '../../../data/services/blackboard_setting_service.dart';
import '../../../domain/models/blackboard_setting_model.dart';
import '../../../utils/global_logger.dart';

class BlackboardSettingViewModel extends ChangeNotifier {

  // サービス読込後に格納する変数（lib/data/services/blackboard_setting_service.dart）
  // テストの時しか使いません
  final BlackboardSettingService? _service;

  // final：一度だけ代入できる（再代入不可）実行時に決まる
  // const：コンパイル時に確定する「完全に不変な定数」	コンパイル時に値が確定してないとダメ

  // TextEditingController：TextFieldの入力値をコードから取得・設定するためのコントローラーを定義
  final TextEditingController projectController = TextEditingController();
  final TextEditingController siteController = TextEditingController();
  final TextEditingController forestController = TextEditingController();

  // ドロップダウンはTextEditingControllerのようなコントローラーがないようです。
  // なので、各所でsetStateやUIでonChangeトリガーでリアクティブにしており、テキストボックスの実装方法が全然違う
  //
  // ドロップダウンの選択された値を保存する変数の初期定義
  // 初期値いれないとnullエラーになる
  //
  // 書き分け補足
  // 変数定義をサービスに書くのは趣旨からずれるのでNG
  // セレクトのvalueの定義なのでViewModelに書くのセオリー
  //
  // defaultWorkTypeはデータ取得時の初期値として、サービスで初期値のnull対応するのでサービスに書く
  // （判断理由がわかりにくいけど、そういうものらしい）
  int selectedWorkTypeKey = BlackboardSettingModel.defaultWorkTypeKey;

  // 初期化をコンストラクタ引数で直接行う
  // finalは代入不可なので、この書き方じゃないとエラーになる
  //
  // テストのときだけ利用。サービスのモックの都合上分離するために引数で渡すことが必要
  // 本番ではサービス自分自身を参照するので使わない
  //
  // []
  // 引数を省略可能にする（[]で囲むことで任意化）
  BlackboardSettingViewModel([this._service]);

  // 保存されたデータを読み込む（SharedPreferences）
  Future<void> loadData() async {
    final service = _service ?? BlackboardSettingService();
    // サービスの読み込み処理を使いデータを参照
    final data = await service.load();

    // 参照データをUIに渡す
    // !について：サービスでnull返らないようにしてるので、エラー対策でつけてる
    projectController.text = data[BlackboardSettingModel.projectKey]!;
    siteController.text = data[BlackboardSettingModel.siteKey]!;
    forestController.text = data[BlackboardSettingModel.forestKey]!;
    selectedWorkTypeKey = data[BlackboardSettingModel.workTypeKey]!;
    notifyListeners(); // UIに変更通知し表示
  }

  // 入力されたデータを保存する
  Future<bool> saveData() async {
    final service = _service ?? BlackboardSettingService();
    // try cathe書くべき場所
    //
    // サービス：基本は書かなくてOKだが、具体的に重要な場合だけ書く
    // ViewModel：実行箇所なのでここにtry catheかく
    try {
      // 失敗させる場合の仮コード
      // TODO:ゆくゆくはテストコードの作り方を調べるので、その時に一番いいやり方を確認する
      // throw Exception('テスト用に強制失敗させています');

      // サービスの保存処理を使いデータを保存
      await service.save(
        project: projectController.text,
        site: siteController.text,
        workTypeKey: selectedWorkTypeKey,
        forest: forestController.text,
      );
      return true;
    } catch (e) {
      logger.e('保存失敗: $e');
      return false;
    }
  }

  // ドロップダウンの値を変更する
  void updateWorkType(int? key) {
    if (key != null) {
      selectedWorkTypeKey = key;
      notifyListeners(); // UIに通知
    }
  }

  // メモリリーク対策：disposeも用意
  // TextEditingControllerはメモリを使うので、手動でdisposeが必要らしい
  //
  // ChangeNotifierProviderを使うとFlutterが自動で ViewModel を生成し、不要になったら .dispose() も自動で呼びます
  // コントローラー名はdisposeと分かりやすい方が良いが任意で好きにできる
  // コントローラー名で開発者が特に呼ぶことは基本無いはず
  void disposeControllers() {
    projectController.dispose();
    siteController.dispose();
    forestController.dispose();
  }
}
