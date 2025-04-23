import 'package:flutter_test/flutter_test.dart';
import 'package:work_photo_app_sample/domain/models/blackboard_setting_model.dart';

void main() {
  group('BlackboardSettingModel', () {
    test('【モデルテスト】toMapでMap化されることを確認', () {
      const model = BlackboardSettingModel(
        project: 'テスト事業',
        site: 'テスト現場',
        workTypeKeyVal: 0,
        forestSubdivision: '林小班A',
      );

      // ↑のmodelの値がmap化されて返ってくればOK
      // expect(実際の値, 期待する値や条件);
      expect(model.toMap(), {
        BlackboardSettingModel.projectKey: 'テスト事業',
        BlackboardSettingModel.siteKey: 'テスト現場',
        BlackboardSettingModel.workTypeKey: 0,
        BlackboardSettingModel.forestKey: '林小班A',
      });
    });

    // fromMap() は現在使っていないためテストしない
  });
}
