import 'package:flutter/material.dart';
import '../../../data/services/blackboard_setting_service.dart';

class BlackboardSettingViewModel extends ChangeNotifier {

  // サービス読込（lib/data/services/blackboard_setting_service.dart）
  final BlackboardSettingService _service = BlackboardSettingService();

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
  // 変数定義をサービスに書くのは趣旨からずれるのでNG。セレクトのvalueの定義なのでViewModelに書くのセオリー
  // defaultWorkTypeはデータ取得時の初期値として、サービスで初期値のnull対応するのでサービスに書く
  // （判断理由がわかりにくいけど、そういうものらしい）
  String selectedWorkType = BlackboardSettingService.defaultWorkType;

  // 保存されたデータを読み込む（SharedPreferences）
  Future<void> loadData() async {
    // サービスの読み込み処理を使いデータを参照
    final data = await _service.load();

    // 参照データをUIに渡す
    // !について：サービスでnull返らないようにしてるので、エラー対策でつけてる
    projectController.text = data['projectName']!;
    siteController.text = data['siteName']!;
    forestController.text = data['forestUnit']!;
    selectedWorkType = data['workType']!;
    notifyListeners(); // UIに変更通知し表示
  }

  // 入力されたデータを保存する
  Future<void> saveData() async {
    // サービスの保存処理を使いデータを保存
    await _service.save(
      project: projectController.text,
      site: siteController.text,
      forest: forestController.text,
      workType: selectedWorkType,
    );
  }

  // ドロップダウンの値を変更する
  void updateWorkType(String? value) {
    if (value != null) {
      selectedWorkType = value;
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
