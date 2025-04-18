// 黒板設定用モデルクラス（immutable推奨）
//
// モデル定義のポイント
//
// immutable(不変)にする
// - final：一度だけ代入できる（再代入不可）実行時に決まる
// - const：コンパイル時に確定する「完全に不変な定数」	コンパイル時に値が確定してないとダメ
//
class BlackboardSettingModel {
  // 事業名（テキスト入力）
  final String project;

  // 現場名（テキスト入力）
  final String site;

  // 作業種（作業前、作業中、作業後）（ドロップダウン選択）
  final int workTypeKey;

  // 林小班（テキスト入力）
  final String forestSubdivision;

  // コンストラクター（すべての値を必須にする）
  // required：インスタンス作成時に引数にこの4つの値が揃わないとインスタンスが作れなくなる
  // もし一つでも値をセットし忘れるとエラーになる（バリデーションとは違うが近い動作）
  const BlackboardSettingModel({
    required this.project,
    required this.site,
    required this.workTypeKey,
    required this.forestSubdivision,
  });

  // ここのJSON←→MAPの変換はshared_preferencesへの保存、参照の理解で紛らわしいが、
  // これがあることで実行箇所で一個ずつ書かなくてよくなり、今後の改修漏れを防ぎやすくなるので推奨されてるらしい
  // そもそも文字列でしか保存できないのもあるので、まとめる場合こうなる
  //
  // 例）サービスの保存処理（Future<void> save()）実行箇所で以下のように変わる
  //
  // （変更前）
  // final prefs = await SharedPreferences.getInstance();
  // await prefs.setString(_projectKey, project);
  // await prefs.setString(_siteKey, site);
  // await prefs.setString(_forestKey, forest);
  // await prefs.setString(_workTypeKey, workType);
  //
  // ↓
  //
  // （変更後）
  // final prefs = await SharedPreferences.getInstance();
  // await prefs.setString('blackboard_setting', jsonEncode(setting.toMap()));
  //
  // なお、Freezedパッケージを使うと「不変モデル＋toMap/fromMap/コピー機能」など全部自動化出来るらしいが、
  // 後で余裕あればする
  //
  // shared_preferencesで保存するためにMap形式に変換する
  // ※サービス側で使うときはこのMapがjsonEncode(setting.toMap())みたいな感じでJSON文字列化してまとめて入れる

  // メソッドの定義
  // Map<String, dynamic>：戻り値の型：Map（即座に返す）
  // toMap：メソッド名
  //
  // dynamic
  // どんな型でもOK（あとからでも変えられる）
  // int や String や bool などいろんな型が来るかもしれないから dynamic にしておく」という意味
  // 変数の型をコンパイル時にチェックしないことを明示的に示すキーワード
  // 型チェックは実行時まで遅延されます。
  // そのため、コンパイル時にはエラーにならないコードでも、実行時に型に関連するエラーが発生する可能性があるので、多用はNG
  // TODO：toMap、fromMapつかってないけど、保存のとこかきかえないといけない？個人的にtoMap、fromMapなくてもいいような気がする。複雑化するだけ？
  // TODO:Serviceのload()、Save()書き直した方が良い？
  Map<String, dynamic> toMap() {
    return {
      'project': project,
      'site': site,
      'workTypeKey': workTypeKey,
      'forestSubdivision': forestSubdivision,
    };
  }

  // shared_preferencesから取り出したJson文字列をMapに戻して返す
  // ※toMap()でJSON文字列化してるので、MAPに戻す処理
  //
  // メソッドの定義
  // factory：自作の特別なコンストラクタを示すキーワード（今回はMapからインスタンスを作るためのfactoryコンストラクタを自作）
  // BlackboardSettingModel：戻り型
  // .fromMap(...)：名前付きコンストラクタ名
  // Map<String, dynamic>：戻り値の型：Map（即座に返す）
  //
  // 名前付きコンストラクタ名について
  // .fromMap(...)：名前付きコンストラクタ名を作るメリットはわかりません。
  // 実行時の書き方も変わらないし。
  // factoryは自作の特別なコンストラクタを示すキーワードなのでこの書き方が推奨と覚えるのが速いかも

  // ChatGPT曰く以下がメリットらしいです
  //
  // BlackboardSettingModel.fromMap(...) と書いた瞬間に、
  // 「お、これはモデルを作ってるな」って 読み手にもプログラムにもはっきり伝わる。
  //
  // ちなみに名前付きコンストラクタ名じゃなくてもできるらしいです
  //
  // - staticバージョン：static BlackboardSettingModel fromMap(...)
  // - 名前付きコンストラクタバージョン：factory BlackboardSettingModel.fromMap(...)
  factory BlackboardSettingModel.fromMap(Map<String, dynamic> map) {
    return BlackboardSettingModel(
      project: map['project'] ?? '',
      site: map['site'] ?? '',
      workTypeKey: map['workTypeKey'],
      forestSubdivision: map['forestSubdivision'] ?? '',
    );
  }

  // Mapの型定義について
  //
  // なぜint小文字でString大文字？
  // - int、double、bool：プリミティブ型（int型）	小文字	Dart言語がビルトインで持ってる基本型
  // - String、List<T>、Map<K,V>、Set<T>：クラス型（文字列クラス）	大文字	String は class String {} で定義されている
  //
  // 型定義書くときに、IDEでもプリミティブ型かクラス型判別つかないので厄介・・エラー出るので察して書き直して・・
  static const int defaultWorkTypeKey = 0; // 初期値
  static const Map<int,String> workTypeOptions = {
    defaultWorkTypeKey : '作業前',
    1 : '作業中',
    2 : '作業後',
    3 : '作業中断', // 追加される可能性あり
  };
}
