
import 'package:test/test.dart';
import 'package:work_photo_app_sample/counter_test_sample.dart';

// テストクラス
void main() {
  // 複数の処理をまとめるためにはgroup使う
  group('テスト開始：lib/counter_test_sample.dart', () {
    test('初期値か0かテスト', () {
      expect(Counter().value, 0);
    });

    // 一個目のテスト
    test('値がインクリメント(+)されるて1になるかテスト', () {
      final counter = Counter();

      counter.increment();

      expect(counter.value, 1);
    });

    // 二個目のテスト
    test('値がデクリメント(-)されて-1になるかテスト', () {
      final counter = Counter();

      counter.decrement();

      expect(counter.value, -1);
    });
  });
}