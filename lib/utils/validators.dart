// バリデーション条件を記載するクラス
//
// ここに条件を記載しWidgetで利用します。
//
// Flutterに基本的なバリデーション機能がなく、自作前提なのがありえないのはそもそもですが、
// 条件を自作しないといけない以上、簡潔で安全であり、今後事故が起きないようにしておく必要があります
// なので、条件実装時は以下を意識すると良いと思います。
//
// - シンプルで簡潔
// - 誰が見てもパッと理解できる
// - 以下のように複合的に複雑に書かない
// - 重複した条件を定義しない
//
// なおパッケージ「flutter_form_builder + form_builder_validators」もありますが、
// FlutterのState+Controllerの仕様と競合するらしく、コードが不自然で読みづらくなるので実装を諦めました
// （内部解析しないとなんで危険なのかわからないレベルらしいです）
//
// 必須 + 最大文字数の複合チェック
// static String? requiredWithMax(String? value, int max, {String label = 'この項目'}) {
//   return required(value, label: label) ?? maxLength(value, max, label: label);
// }
import '../config/messages.dart';

class Validators {
  // 必須チェック(テキスト用)
  static String? required(String? value, {String label = 'この項目'}) {
    if (value == null || value.trim().isEmpty) {
      return Messages.validation.required(label);
    }
    return null;
  }

  // セレクト（Dropdownなど）必須チェック
  // dynamic 型にしているのは、セレクトの value が int, String, bool などいろいろな型になる可能性があるため
  static String? selectRequired(dynamic value, {String label = 'この項目'}) {
    if (value == null) {
      return Messages.validation.selectRequired(label);
    }
    return null;
  }

  // 最大文字数チェック
  static String? maxLength(String? value, int max, {String label = 'この項目'}) {
    if (value != null && value.length > max) {
      // info: Unnecessary braces in a string interpolation
      // 単一の場合に波かっこは不要の警告：{$max}→$maxにする
      return Messages.validation.maxLength(label,max);
    }
    return null;
  }


}
