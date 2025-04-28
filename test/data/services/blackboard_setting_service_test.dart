
// 🟡 SharedPreferences のモックを自動生成する指定
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:work_photo_app_sample/data/services/blackboard_setting_service.dart';
import 'package:work_photo_app_sample/domain/models/blackboard_setting_model.dart';

import 'blackboard_setting_service_test.mocks.dart';

// TODO:完成させて動作確認する
@GenerateMocks([SharedPreferences])
void main() {
  // 🔧 テスト準備
  late MockSharedPreferences mockPrefs;
  late BlackboardSettingService service;

  // 📦 テスト用データ
  // modelは使うときだけ必要だが、今回は不要
  // const model = BlackboardSettingModel(
  //   project: 'テスト事業',
  //   site: 'テスト現場',
  //   workTypeKeyVal: 1,
  //   forestSubdivision: '林小班A',
  // );

  // setUp使い分け
  // ・setUp() に書く：すべてのテスト項目で共通して必要な準備
  // ・共通関数：一部のテストだけで使う処理
  setUp(() {
    mockPrefs = MockSharedPreferences(); // モックを生成
    service = BlackboardSettingService(mockPrefs); // Serviceに注入
  });

  // ✅ 保存成功のテスト
  test('保存が成功する', () async {
    // モック
    // すべての setString(サービスで使ってるSharedPreferencesの保存メソッド) が true を返すように設定
    // （→ 保存できたことにする）
    //
    // - SharedPreferencesの保存メソッドのモックを設定することで、本物のSharedPreferencesを動かさずに本物への保存を防ぐ
    //　- 本物のSharedPreferencesを動かさずに、本物のSharedPreferencesが成功前提(true)でのテストにする
    // 　（仮に本物のSharedPreferencesを動かすようなテストにすると、ローカルストレージだが本番で間違って動かしたら危ないかもしれないので）
    // ＝このことからテスト方針は、サービスのsaveメソッドのテストだが、SharedPreferences以外の機能のテストになる
    //
    // じゃあ「SharedPreferences」のテストしないの？
    // ここが成功するかが肝心ではないのか？
    //　→結論OK
    //
    // ・テストはSharedPreferencesで「保存処理は基本失敗しない」という前提で作られることが多い
    // ・外部依存の内部動作なので（SharedPreferences の保存処理）、ユニットテストの範囲外
    // ・自分たちは正しくSharedPreferencesを呼べているかだけでいい
    // ・本物の「SharedPreferences」を動かす以外に方法がないので、これでいい
    // ・結果がエラーのときは呼び出し元のview_modelのtry catchでしてるので、統合テストでするしかない
    // TODO:統合テストでも本物の「SharedPreferences」を動かす以外に方法がないとは思うが、統合テストはまだ未調査なのでそのときにどうするのが一般的か調べる
    //
    // when：モックオブジェクトのメソッドが特定の引数で呼び出されたときに、どのような動作をさせるかを設定
    // mockPrefs.setString(any, any)：mockPrefs オブジェクトの setString メソッドが、任意の引数で呼び出された場合、という意味
    // thenAnswer：when で指定したメソッド呼び出しがあった場合に、どのような戻り値を返すかを設定
    // 　　　　　　　非同期処理 (async) で true を返す関数を定義しています。
    // 　　　　　　　引数 _ は、setString に渡される引数ですが、ここでは使用しないことを意味します
    // 　　　　　　　mockPrefs.setString が呼ばれると、非同期的に true を返すように設定しています
    when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
    when(mockPrefs.setInt(any, any)).thenAnswer((_) async => true);

    final result = await service.save(
      project: 'テスト事業',
      site: 'テスト現場',
      workTypeKey: 1,
      forest: '林小班A',
    );

    // サービスからtrueが返ってくるかテスト
    expect(result, isTrue);

    // verify：whenが成功したか（→ 保存できたことにするが成功したか）
    // 　　　　　本当に「そのキーと値」でモックに保存しようとしたかをチェック
    // .called(1)：「1回呼ばれた」ことを検証
    verify(mockPrefs.setString(BlackboardSettingModel.projectKey, 'テスト事業')).called(1);
    verify(mockPrefs.setString(BlackboardSettingModel.siteKey, 'テスト現場')).called(1);
    verify(mockPrefs.setInt(BlackboardSettingModel.workTypeKey, 1)).called(1);
    verify(mockPrefs.setString(BlackboardSettingModel.forestKey, '林小班A')).called(1);
  });

  // ✅ 保存失敗のテスト
  //  本当ならキーが間違ってたらfalseとかにしないと意味がうすれる気がするが・・
  //  最初からfalseで動かしてるだけだから、これでいいのか？となる
  //
  // やってること↓
  //  - when()でSharedPreferencesの保存メソッドをモックで失敗で呼び出す
  //  - サービスを動かす
  //  - verify().called(1)でSharedPreferencesメソッドが失敗で正しく呼ばれたかを引数のキー、バリュー完全一致で定義しチェック
  //
  //  これでやるしかないのが間違いなく、一般的ということですよね・・
  test('保存が失敗する', () async {
    when(mockPrefs.setString(any, any)).thenAnswer((_) async => false);
    when(mockPrefs.setInt(any, any)).thenAnswer((_) async => false);

    final result = await service.save(
      project: 'テスト事業',
      site: 'テスト現場',
      workTypeKey: 1,
      forest: '林小班A',
    );

    // サービスからfalseが返ってくるかテスト
    expect(result, isFalse);

    // 失敗パターン
    //
    // なぜ一個なのか？
    // モックでfalseで動かしてるので一個目の保存でfalseが返ってくるため、一個でOK
    // 後続があるとテストが失敗する（最初に失敗したらreturn falseするので、その後は呼ばれないため）
    verify(mockPrefs.setString(BlackboardSettingModel.projectKey, 'テスト事業')).called(1);
  });

  // ✅ 読込成功のテスト
  // test('保存済みのデータを読み込める', () async {
  //   // モック：getString に返す値を設定
  //   when(mockPrefs.getString('project')).thenReturn('読み込み事業');
  //   when(mockPrefs.getString('site')).thenReturn('読み込み現場');
  //   when(mockPrefs.getString('workType')).thenReturn('2');
  //   when(mockPrefs.getString('forest')).thenReturn('林小班X');
  //
  //   final loaded = await service.loadSetting();
  //
  //   expect(loaded.project, '読み込み事業');
  //   expect(loaded.site, '読み込み現場');
  //   expect(loaded.workTypeKeyVal, 2);
  //   expect(loaded.forestSubdivision, '林小班X');
  // });

}