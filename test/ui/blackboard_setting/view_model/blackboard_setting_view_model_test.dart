
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:work_photo_app_sample/data/services/blackboard_setting_service.dart';
import 'package:work_photo_app_sample/ui/blackboard_setting/view_model/blackboard_setting_view_model.dart';
import 'blackboard_setting_view_model_test.mocks.dart';

// モックを使う理由
// テスト対象が依存している外部の振る舞いを"意図的に制御する"ことで、テスト対象の挙動だけに集中するために使う
//
// よくあるモック対象
// DBアクセス：遅い・外部依存がある・エラー再現が難しい
// ネットワークAPI：接続不安定・レスポンス変動・遅い
// SharedPreferences：実機に依存・初期化が必要
// サービスクラス：他のビジネスロジックを含むため、テスト粒度を分けるため

// ViewModelからServiceへ渡す入力値の共通化
const String projectInput = 'プロジェクト名';
const String siteInput = '現場名';
const int workTypeInput = 1;
const String forestInput = '林小班';

// @GenerateMocksについて
// flutter pub run build_runner build を実行して .mocks.dart を生成しないといけない
// これをすると対象のモッククラスをimportできる
@GenerateMocks([BlackboardSettingService])
void main() {
  late MockBlackboardSettingService mockService;
  late BlackboardSettingViewModel viewModel;

  setUp(() {
    // インスタンスセットアップ
    mockService = MockBlackboardSettingService();
    viewModel = BlackboardSettingViewModel(mockService);
  });

  test('保存成功時に true を返す', () async {
    // モックの設定
    // 成功前提なので、これが一般的なテスト？
    // と少し不安だが、対象のテスト（今回はViewModel）に集中するためにはこれが一般的な書き方で使い方とのこと
    // （対象のテストに集中するためにサービスはモックにして本番に依存せずテスト実行している）

    // サービスのsaveを成功前提でtrueで返すようにモックを設定
    when(mockService.save(
      // eq() は値のチェックをできるが、名前付き引数（named parameters）では使えない
      // project: eq('プロジェクト名'),
      // ↓　
      // project: argThat(equals('プロジェクト名'), named: 'project'),
      //
      // これなら書けるが、自作になるし、長いしそもそも値は固定でいいので直接値を書くようにした
      // ViewModelから渡すときに値が↓の値と一致しないとテスト失敗するようにしています
      project: projectInput,
      site: siteInput,
      workTypeKey: workTypeInput,
      forest: forestInput,
    )).thenAnswer((_) async => true);

    // anyNamedについて
    //
    // 引数の名前だけ一致すればOK
    // ※値は見ないので、本番のサービスの引数ではrequireがあるが、ここに値がなくてもエラーにならない
    // ※型違いは実行以前にDartの構文チェックでエラーにはなる
    //
    // 使っても意味ないと個人的に思ったので使ってません。
    // when(mockService.save(
    //   project: anyNamed('project'),
    //   site: anyNamed('site'),
    //   workTypeKey: anyNamed('workTypeKey'),
    //   forest: anyNamed('forest'),
    // )).thenAnswer((_) async { return true; });

    // ViewModelでサービスを使う前に入力値をViewModelに渡す
    viewModel.projectController.text = projectInput;
    viewModel.siteController.text = siteInput;
    viewModel.selectedWorkTypeKey = workTypeInput;
    viewModel.forestController.text = forestInput;

    // ViewModelのsaveDataメソッドでサービスのsave（モック）を動かしてテスト
    final result = await viewModel.saveData();

    // サービス実行後に正しい値でサービスを呼んだか確認
    verify(mockService.save(
      project: projectInput,
      site: siteInput,
      workTypeKey: workTypeInput,
      forest: forestInput,
    ));

    // 結果がViewModelが動いた結果がtrueなら成功
    expect(result, true);
  });

  test('保存失敗時に false を返す', () async {
    when(mockService.save(
      project: projectInput,
      site: siteInput,
      workTypeKey: workTypeInput,
      forest: forestInput,
    )).thenThrow(Exception('保存失敗'));

    viewModel.projectController.text = projectInput;
    viewModel.siteController.text = siteInput;
    viewModel.selectedWorkTypeKey = workTypeInput;
    viewModel.forestController.text = forestInput;

    final result = await viewModel.saveData();

    verify(mockService.save(
      project: projectInput,
      site: siteInput,
      workTypeKey: workTypeInput,
      forest: forestInput,
    ));

    expect(result, false);
  });
}