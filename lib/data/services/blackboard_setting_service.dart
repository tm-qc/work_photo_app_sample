import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/blackboard_setting_model.dart';

class BlackboardSettingService {

  // SharedPreferencesを引数で受け取るために追加
  // テスト時にモック代入するためだけに使う、本番では使わない
  // （テストの分離のためだけというのが腑に落ちないけどこうしないと現状できなかった）
  final SharedPreferences? _prefs;

  // 初期化をコンストラクタ引数で直接行う
  // finalは代入不可なので、この書き方じゃないとエラーになる
  //
  // thisについて
  // Dartでは以下らしい。独特過ぎる印象
  //
  // ↓this必要
  // - 同名の引数と区別したいとき
  // - 今回のように省略記法（this.value）で代入する時
  //
  // ↓this不要
  // 参照するだけのとき
  //
  // []
  // 引数を省略可能にする（[]で囲むことで任意化）
  BlackboardSettingService([this._prefs]);

  // save関数の定義（非同期 async await）
  // Future<void>：非同期処理で、完了したことだけ返す（値は返さない）
  //
  // メソッドの定義
  // Future<void>	戻り値の型（非同期処理：結果なし）
  // save	メソッド名（関数名）
  // ({})	名前付き引数のブロック
  // async	この関数は非同期処理（await使えるよ）
  Future<bool> save({
    // 名前付き引数（必須）
    required String project,
    required String site,
    required int workTypeKey,
    required String forest,
  }) async {
      try {
        // mapにするまえにモデルのコンストラクタで入力値を持ったインスタンス作成
        final model = BlackboardSettingModel(
          project: project,
          site: site,
          workTypeKeyVal: workTypeKey,
          forestSubdivision: forest,
        );

        // 定義を安全にまとめるためにインスタンスを利用して入力値をmapにまとめる
        final map = model.toMap();

        // 非同期で端末保存データSharedPreferencesを取得
        final prefs = _prefs ?? await SharedPreferences.getInstance();

        // mapをループで保存
        //
        // for in にした理由
        // ・map.forEachではawaitが機能しない
        // ・forEach 内の await 式で発生した例外はキャッチできません
        // 　（awaitなければ例外キャッチできるみたいです）
        //
        // map.entries：Mapの「キーとバリューのペア」を1組ずつ取り出すためのDart公式のお決まりの書き方
        for (final entry in map.entries) {
          if (entry.value is String) {
            final result = await prefs.setString(entry.key, entry.value);
            if (!result) return false;//保存失敗
          }
          if (entry.value is int) {
            final result = await prefs.setInt(entry.key, entry.value);
            if (!result) return false;//保存失敗
          }
        }
        return true;//保存成功
      } catch (e){
        // 予期せぬエラー
        // TODO：Don't invoke 'print' in production code.なので削除か、ログに書き出すようにする
        print('保存失敗: $e'); // ログ出力だけでもOK
        return false;
      }
    }

  // 読み込み処理（保存された設定をすべてMapで返す）
  //
  // メソッドの定義
  // Future<Map<String, String>>	戻り値の型：Map（非同期に返される）
  // <String, String>	Mapのキーと値の型（文字列と文字列）
  // load	関数名（メソッド名）
  // async	非同期処理（awaitが使える）

  // 型について
  // - keyだけint、他はstring
  // - 複数型定義はない
  // こういう状態なのでモデルに合わせてdynamicに変更
  // ここの型が違うとサービスを使ってるview_modelでエラーになる
  Future<Map<String, dynamic>> load() async {
    // SharedPreferences を保存されたデータを読む
    final prefs = await SharedPreferences.getInstance();

    // 各項目を読み込んでMap形式で返す（nullなら空文字 or 作業前）
    // Mapとは
    // いわゆる連想配列。Key:valueで順番の保証はなし
    // ※ちなみに普通の配列(Keyなし+順番保障)はListになる
    // 参考
    // https://dart.dev/language/collections#maps
    return {
      BlackboardSettingModel.projectKey: prefs.getString(BlackboardSettingModel.projectKey) ?? '',
      BlackboardSettingModel.siteKey: prefs.getString(BlackboardSettingModel.siteKey) ?? '',
      BlackboardSettingModel.workTypeKey: prefs.getInt(BlackboardSettingModel.workTypeKey) ?? BlackboardSettingModel.defaultWorkTypeKey,
      BlackboardSettingModel.forestKey: prefs.getString(BlackboardSettingModel.forestKey) ?? '',
    };
  }
}