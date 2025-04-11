import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlackboardSetting extends StatefulWidget {
  const BlackboardSetting({super.key});

  // なんで@overrideいるんだっけ？
  // StatefulWidget の定義済みメソッドなので、上書きすることを明示
  // 「親クラスで定義されているメソッドを子クラスで上書き（override）」するときに @override をつけます。
  @override
  State<BlackboardSetting> createState() => _BlackboardSettingState();
}
class _BlackboardSettingState extends State<BlackboardSetting> {
  // final：一度だけ代入できる（再代入不可）実行時に決まる
  // const：コンパイル時に確定する「完全に不変な定数」	コンパイル時に値が確定してないとダメ

  // nullエラー対策の初期値
  // TODO:null NG 初期値が必要なので一旦これで。全体の流れにそってハードコーディングは解消しないといけない
  static const String defaultWorkType = '作業前';

  // TextEditingController：TextFieldの入力値をコードから取得・設定するためのコントローラーを定義
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _forestController = TextEditingController();

  // ドロップダウンはTextEditingControllerのようなコントローラーがないようです。
  // なので、各所でsetStateやUIでonChangeトリガーでリアクティブにしており、テキストボックスの実装方法が全然違う

  // ドロップダウンの選択された値を保存する変数
  // 初期値いれないとnullエラーになる
  String _selectedWorkType = defaultWorkType;

  // State クラスに定義されているライフサイクルメソッドを上書きしているため、 @override が必要
  // initState() はウィジェットが画面に表示される前に一度だけ呼ばれる初期化処理
  @override
  void initState() {
    super.initState();
    _loadSavedData(); // アプリ起動時に保存済データを読み込み
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    // 値だけ変えても表示は更新されないので、画面に再描画行うためにsetStateでリアクティブにして値をセットしてる
    setState(() {
      // .text で現在のテキストを取得・変更できる
      _projectController.text = prefs.getString('projectName') ?? '';
      _siteController.text = prefs.getString('siteName') ?? '';
      _forestController.text = prefs.getString('forestUnit') ?? '';
      // プルダウンなので.text 不要
      // 初期値いれないとnullエラーになる
      _selectedWorkType = prefs.getString('workType') ?? defaultWorkType;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('projectName', _projectController.text);
    await prefs.setString('siteName', _siteController.text);
    await prefs.setString('forestUnit', _forestController.text);
    await prefs.setString('workType', _selectedWorkType);

    // 警告対応：Don't use BuildContexts across async gaps
    // 非同期処理（await）のあとに context を使うとアプリがクラッシュする可能性がある という警告
    // 非同期処理のあとで context を使う前に、ウィジェットがまだ生きているかを確認することで回避
    // mounted は StatefulWidget に自動でついてくる「ウィジェットがまだ画面上に存在しているか？」を示すプロパティです。
    if (!mounted) return;

    // 画面下に一時的に「メッセージ」を表示する方法（いわゆるトースト通知的なやつ）
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('保存しました')),
    );
  }

  // ここからUI

  //
  @override
  Widget build(BuildContext context) {
    // Scaffold：アプリの基本構造（AppBar・bodyなど）
    return Scaffold(
      appBar: AppBar(title: Text('黒板設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 余白
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 左揃え
          children: [
            // 事業名
            Text('事業名'),
            TextField(
              // TextField とコントローラーが紐づくことで、入力された値をプログラム側で取得・セットできる。
              controller: _projectController,
              decoration: InputDecoration(hintText: '例：〇〇事業'),
            ),
            SizedBox(height: 16), // 間隔

            // 現場名
            Text('現場名'),
            TextField(
              controller: _siteController,
              decoration: InputDecoration(hintText: '例：△△現場'),
            ),
            SizedBox(height: 16),

            // 作業種（ドロップダウン）
            Text('作業種'),
            DropdownButtonFormField<String>(
              // 今選択されている値（＝選択状態を保持する変数）を指定
              // テキストボックスとcontrollerの紐づけの書き方が大分違うので戸惑うが、ドロップダウンはコントローラーがないのでこれで覚えるしかない
              value: _selectedWorkType,
              items: ['作業前', '作業中', '作業後'].map((label) => DropdownMenuItem(
                value: label,
                child: Text(label),
              ))
                  .toList(),
              // 自動的に中身は更新されないので、自分で setState() して変えてあげる必要がある
              // TextFieldは「保存ボタンを押したタイミングでコントローラーから値を取得」する設計なので onChanged は不要
              onChanged: (value) {
                // 値だけ変えても表示は更新されないので、値をセットするためにsetStateでリアクティブにする
                // テキストボックスはonChangedもsetStateも書かなくていいし、書き方が大分違うので戸惑うが、ドロップダウンはコントローラーがないのでこれで覚えるしかない
                setState(() {
                  // nullであることは絶対にないので!で対応
                  _selectedWorkType = value!;
                });// 今は何も処理しない
              },
              decoration: InputDecoration(
                hintText: '選択してください',
              ),
            ),
            SizedBox(height: 16),

            // 林小班
            Text('林小班'),
            TextField(
              controller: _forestController,
              decoration: InputDecoration(hintText: '例：1-2'),
            ),
            SizedBox(height: 24),

            // 保存ボタン
            Center(
              child: ElevatedButton(
                onPressed: _saveData,
                child: Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
