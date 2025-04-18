import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/blackboard_setting_model.dart';

class BlackboardSettingService {
  // save関数の定義（非同期 async await）
  // Future<void>：非同期処理で、完了したことだけ返す（値は返さない）
  //
  // メソッドの定義
  // Future<void>	戻り値の型（非同期処理：結果なし）
  // save	メソッド名（関数名）
  // ({})	名前付き引数のブロック
  // async	この関数は非同期処理（await使えるよ）
  Future<void> save({
    // 名前付き引数（必須）
    required String project,
    required String site,
    required int workTypeKey,
    required String forest,
  }) async {

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
    final prefs = await SharedPreferences.getInstance();

    // mapをループで保存
    //
    // keyはtoMap()で
    // lib/domain/models/blackboard_setting_model.dartの「保存時に使うローカルストレージのキー」参照してます
    // ローカルストレージのキーを変更したいとき、「保存時に使うローカルストレージのキー」を変更すると思うが、同時変わるので修正漏れも防げるはず
    map.forEach((key, value) async {
      if (value is String) await prefs.setString(key, value);
      if (value is int) await prefs.setInt(key, value);
    });
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