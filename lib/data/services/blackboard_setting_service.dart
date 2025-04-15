import 'package:shared_preferences/shared_preferences.dart';

class BlackboardSettingService {
  // 保存時に使うローカルストレージのキー（キー名のミス防止のため、定数化）
  static const String _projectKey = 'projectName';
  static const String _siteKey = 'siteName';
  static const String _forestKey = 'forestUnit';
  static const String _workTypeKey = 'workType';

  // 初期値：ドロップダウンのデフォルト値
  // nullエラー対策の初期値
  // TODO:null NG 初期値が必要なので一旦これで。全体の流れにそってハードコーディングは解消しないといけない
  static const String defaultWorkType = '作業前';

  // save関数の定義（非同期 async await）
  // Future<void>：非同期処理で、完了したことだけ返す（値は返さない）
  Future<void> save({
    // 名前付き引数（必須）
    required String project,
    required String site,
    required String forest,
    required String workType,
  }) async {
    // 非同期で端末保存データSharedPreferencesを取得
    final prefs = await SharedPreferences.getInstance();
    // それぞれのキーと値を保存する
    await prefs.setString(_projectKey, project);
    await prefs.setString(_siteKey, site);
    await prefs.setString(_forestKey, forest);
    await prefs.setString(_workTypeKey, workType);
  }

  // 読み込み処理（保存された設定をすべてMapで返す）
  Future<Map<String, String>> load() async {
    // SharedPreferences を保存されたデータを読む
    final prefs = await SharedPreferences.getInstance();
    // 各項目を読み込んでMap形式で返す（nullなら空文字 or 作業前）
    return {
      _projectKey: prefs.getString(_projectKey) ?? '',
      _siteKey: prefs.getString(_siteKey) ?? '',
      _forestKey: prefs.getString(_forestKey) ?? '',
      _workTypeKey: prefs.getString(_workTypeKey) ?? defaultWorkType,
    };
  }
}