import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlackboardSettingViewModel extends ChangeNotifier {
  // 初期値：ドロップダウンのデフォルト値
  // nullエラー対策の初期値
  // TODO:null NG 初期値が必要なので一旦これで。全体の流れにそってハードコーディングは解消しないといけない
  static const String defaultWorkType = '作業前';

  // final：一度だけ代入できる（再代入不可）実行時に決まる
  // const：コンパイル時に確定する「完全に不変な定数」	コンパイル時に値が確定してないとダメ

  // TextEditingController：TextFieldの入力値をコードから取得・設定するためのコントローラーを定義
  final TextEditingController projectController = TextEditingController();
  final TextEditingController siteController = TextEditingController();
  final TextEditingController forestController = TextEditingController();

  // ドロップダウンはTextEditingControllerのようなコントローラーがないようです。
  // なので、各所でsetStateやUIでonChangeトリガーでリアクティブにしており、テキストボックスの実装方法が全然違う

  // ドロップダウンの選択された値を保存する変数
  // 初期値いれないとnullエラーになる
  String selectedWorkType = defaultWorkType;

  // ↓これいらない？
  // initState() はウィジェットが画面に表示される前に一度だけ呼ばれる初期化処理
  //
  // initState() は StatefulWidget専用のライフサイクルメソッドなので不要
  // かわりに画面側のcreate: (_) => BlackboardSettingViewModel()..loadData()で呼び出してる
  // @override
  // void initState() {
  //   super.initState();
  //   _loadSavedData(); // アプリ起動時に保存済データを読み込み
  // }

  // 保存されたデータを読み込む（SharedPreferences）
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    // .text で現在のテキストを取得・変更できる
    projectController.text = prefs.getString('projectName') ?? '';
    siteController.text = prefs.getString('siteName') ?? '';
    forestController.text = prefs.getString('forestUnit') ?? '';
    // プルダウンなので.text 不要
    // 初期値いれないとnullエラーになる
    selectedWorkType = prefs.getString('workType') ?? defaultWorkType;
    notifyListeners(); // UIに変更通知
  }

  // 入力されたデータを保存する
  Future<void> saveData(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('projectName', projectController.text);
    await prefs.setString('siteName', siteController.text);
    await prefs.setString('forestUnit', forestController.text);
    await prefs.setString('workType', selectedWorkType);

    // 警告対応：Don't use BuildContexts across async gaps
    // 非同期処理（await）のあとに context を使うとアプリがクラッシュする可能性がある という警告
    // 非同期処理のあとで context を使う前に、ウィジェットがまだ生きているかを確認することで回避
    // mounted は StatefulWidget に自動でついてくる「ウィジェットがまだ画面上に存在しているか？」を示すプロパティです。
    //
    // 今回ここでは以下の理由でチェックできない
    // - mounted は StatefulWidget に自動で付与されるプロパティ
    // - ChangeNotifier には無い
    // - ViewModel が context を使うときは、画面が破棄されたかどうかチェックができない
    // TODO: 理想的には UI 側でトースト表示する
    // if (!mounted) return;

    // contextを使ってトースト通知（mountedチェック不要はなんで？）
    // Don't use 'BuildContext's across async gaps.はどうする？
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('保存しました')),
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
