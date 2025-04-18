import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/blackboard_setting_model.dart';

class BlackboardSettingService {
  // 保存時に使うローカルストレージのキー（キー名のミス防止のため、定数化）
  // TODO；view_model、model、serviceで使うので、private(_)外し、modelに定義して同じものを使うようにする予定。混乱するし保守性低くなる
  static const String _projectKey = 'projectName';
  static const String _siteKey = 'siteName';
  static const String _forestKey = 'forestUnit';
  static const String _workTypeKey = 'workTypeKey';

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
    required String forest,
    required int workTypeKey,
  }) async {
    // 非同期で端末保存データSharedPreferencesを取得
    final prefs = await SharedPreferences.getInstance();
    // それぞれのキーと値を保存する
    await prefs.setString(_projectKey, project);
    await prefs.setString(_siteKey, site);
    await prefs.setString(_forestKey, forest);
    await prefs.setInt(_workTypeKey, workTypeKey);
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
      _projectKey: prefs.getString(_projectKey) ?? '',
      _siteKey: prefs.getString(_siteKey) ?? '',
      _forestKey: prefs.getString(_forestKey) ?? '',
      _workTypeKey: prefs.getInt(_workTypeKey) ?? BlackboardSettingModel.defaultWorkTypeKey,
    };
  }
}