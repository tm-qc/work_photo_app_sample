
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

      // テストのメソッド(=matcher)について
      //
      // このインポートがあればmatcherはつかえる
      // import 'package:flutter_test/flutter_test.dart';
      //
      // expect(実際の値, 期待する値や条件);
      //
      // testパッケージ公式
      // https://pub.dev/packages/test#writing-tests
      //
      // expectpackage:matcher（メソッド(matcher)詳細）
      // https://pub.dev/documentation/matcher/latest/index.html
      // ※tesパッケージ公式の最初の方に「expectpackage:matcher」のメソッドを使う旨かいてある
      // ※情報量多すぎて見るのが難しいので参考まで・・
      //
      // とりあえずAIとか検索で出てきたコードの理解したいときにexpectpackage:matcherのページ見ればいいとだけ頭の隅に置いておけばいいと思う・・
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