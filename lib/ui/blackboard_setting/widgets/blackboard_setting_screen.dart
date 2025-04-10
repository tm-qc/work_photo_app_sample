import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/blackboard_setting_view_model.dart';

class BlackboardSettingScreen extends StatelessWidget {
  const BlackboardSettingScreen({super.key});

  // なんで@overrideいるんだっけ？
  // StatefulWidget の定義済みメソッドなので、上書きすることを明示
  // 「親クラスで定義されているメソッドを子クラスで上書き（override）」するときに @override をつけます。
  @override
  Widget build(BuildContext context) {
    // 状態管理provider
    return ChangeNotifierProvider<BlackboardSettingViewModel>(
      // ViewModelを作成し、loadData()で初期値を読み込む
      //
      // 「..loadData()」ドット二つはカスケード演算子
      // 以下の理由でカスケード演算子じゃないといけない
      //
      // .. は 「戻り値を元のインスタンスに保ったまま、メソッドを参照するだけで実行はしない」= 型がBlackboardSettingViewModelで型不一致エラーにならない
      // . は 「その関数の戻り値そのものを返す」= 実行して型がBlackboardSettingViewModelじゃなくなるので型不一致のエラーになる
      create: (_) => BlackboardSettingViewModel()..loadData(),

      // child にUI部分（ビルド後に ViewModel が使えるようになる）
      child: Scaffold(
        appBar: AppBar(title: Text('黒板設定')),
        // ConsumerがproviderのDI機能
        //
        // 主なメリット
        // - ViewModelのインスタンス化	create: () => ...でOK
        // - UIとの接続	Consumerやcontext.watch()でOK
        // - メモリ管理（破棄）	自動で dispose() 呼んでくれる（今回BlackboardSettingViewModelに書いてる）
        // - UI更新通知のトリガー	notifyListeners() だけでOK
        body: Consumer<BlackboardSettingViewModel>(
          // vm = ViewModelインスタンスがConsumerでBlackboardSettingViewModelに型指定され注入される
          builder: (context, vm, _) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('事業名'),
                  TextField(
                    // TextField とコントローラーが紐づくことで、入力された値をプログラム側で取得・セットできる。
                    // vmはViewModel
                    controller: vm.projectController,
                    decoration: InputDecoration(hintText: '例：〇〇事業'),
                  ),
                  SizedBox(height: 16),

                  Text('現場名'),
                  TextField(
                    controller: vm.siteController,
                    decoration: InputDecoration(hintText: '例：△△現場'),
                  ),
                  SizedBox(height: 16),

                  Text('作業種'),
                  DropdownButtonFormField<String>(
                    // 今選択されている値（＝選択状態を保持する変数）を指定
                    // テキストボックスとcontrollerの紐づけの書き方が大分違うので戸惑うが、ドロップダウンはコントローラーがないのでこれで覚えるしかない
                    value: vm.selectedWorkType,
                    items: ['作業前', '作業中', '作業後']
                        .map((label) => DropdownMenuItem(
                      value: label,
                      child: Text(label),
                    ))
                        .toList(),
                    onChanged: vm.updateWorkType,
                    decoration: InputDecoration(hintText: '選択してください'),
                  ),
                  SizedBox(height: 16),

                  Text('林小班'),
                  TextField(
                    controller: vm.forestController,
                    decoration: InputDecoration(hintText: '例：1-2'),
                  ),
                  SizedBox(height: 24),

                  Center(
                    child: ElevatedButton(
                      onPressed: () => vm.saveData(context),
                      child: Text('保存'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
