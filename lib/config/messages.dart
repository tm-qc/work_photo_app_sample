// メッセージ系の共通化
//
// Flutterではmapみたいな感じではなく、クラス分けしたらチェーンで呼べるので
// クラスで階層作るのが一般的らしい？
//
// 参照はこんな感じで出来る
// Messages.validation.required(label)
class Messages {
  static final validation = _ValidationMessages();
}

/// バリデーション用メッセージ
class _ValidationMessages {
  String required(String label) => '$labelは必須です';
  String maxLength(String label, int max) => '$labelは$max文字以内で入力してください';
  String selectRequired(String label) => '$labelを選択してください';
}