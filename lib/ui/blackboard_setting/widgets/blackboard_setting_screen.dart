import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/blackboard_setting_model.dart';
import '../../../utils/validators.dart';
import '../view_model/blackboard_setting_view_model.dart';

class BlackboardSettingScreen extends StatefulWidget {
  const BlackboardSettingScreen({super.key});
  @override
  State<BlackboardSettingScreen> createState() => _BlackboardSettingScreenState();
}

class _BlackboardSettingScreenState extends State<BlackboardSettingScreen> {
  // バリデーションの時にフォームを管理識別するために必要なキー
  final _formKey = GlobalKey<FormState>();

  // なんで@overrideいるんだっけ？
  // StatefulWidget の定義済みメソッドなので、上書きすることを明示
  // 「親クラスで定義されているメソッドを子クラスで上書き（override）」するときに @override をつけます。
  @override
  Widget build(BuildContext context) {
    // 状態管理ChangeNotifierProvider
    // 「この範囲のWidgetツリーで BlackboardSettingViewModel 型のデータを使えるようにする」 という宣言
    // ViewModelのBlackboardSettingViewModelのインスタンスを作成
    return ChangeNotifierProvider<BlackboardSettingViewModel>(
      // ViewModelを作成し、loadData()で初期値を読み込む
      //
      // 「..loadData()」ドット二つはカスケード演算子
      // 以下の理由でカスケード演算子じゃないといけない
      //
      // .. は 「メソッドを実行するが、戻り値を元のインスタンスに保ったままになる」= 型がBlackboardSettingViewModelで型不一致エラーにならない
      // . は 「その関数の戻り値そのものを返す」= 実行して型がBlackboardSettingViewModelじゃなくなるので型不一致のエラーになる
      create: (_) => BlackboardSettingViewModel()..loadData(),

      // child にUI部分（ビルド後に ViewModel が使えるようになる）
      child: Scaffold(
        appBar: AppBar(title: Text('黒板設定')),
        // ConsumerがproviderのDI機能
        // ここでChangeNotifierProviderで作ったインスタンスを受け取る
        // （builder プロパティに指定された関数vmで受け取る）
        //
        // ちなみに・・この builder の中でしか vm は使えない。画面全体で使いたいときは context.watch() を使う
        //
        // 主なメリット
        // - ViewModelのインスタンス化	create: () => ...でOK
        // - UIとの接続	Consumerやcontext.watch()でOK
        // - メモリ管理（破棄）	自動で dispose() 呼んでくれる（今回BlackboardSettingViewModelに書いてる）
        // - UI更新通知のトリガー	notifyListeners() だけでOK
        body: Consumer<BlackboardSettingViewModel>(
          // vm = ViewModelインスタンスがConsumerでBlackboardSettingViewModelに型指定され注入される
          builder: (context, vm, _) {
            // ラベル名、バリデーションの引数などに使うのでmap共通化
            // TODO:正しい定義場所は要検討・クラス化して定数管理？
            const fieldLabels = {
              'project': '事業名',
              'site': '現場名',
              'workType': '作業種',
              'forest': '林小班',
            };

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fieldLabels['project']!),
                    TextFormField(
                      // TextField とコントローラーが紐づくことで、入力された値をプログラム側で取得・セットできる。
                      // vmはViewModel
                      controller: vm.projectController,
                      decoration: InputDecoration(hintText: '例：〇〇事業'),
                      // リアルタイムバリデーション
                      // （送信時まとめてと別に入力時に入力欄の下にバリデーションメッセージを出せる）
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      // バリデーションの条件を複数行う場合は ?? でつなぐ（万が一のnull対応）
                      validator: (value) =>
                          Validators.required(value, label: fieldLabels['project']!) ??
                          Validators.maxLength(value, 30, label: fieldLabels['project']!),
                    ),
                    SizedBox(height: 16),

                    Text(fieldLabels['site']!),
                    TextFormField(
                      controller: vm.siteController,
                      decoration: InputDecoration(hintText: '例：△△現場'),
                      validator: (value) =>
                      Validators.required(value, label: fieldLabels['site']!) ??
                          Validators.maxLength(value, 10, label: fieldLabels['site']!),
                    ),
                    SizedBox(height: 16),

                    Text(fieldLabels['workType']!),
                    DropdownButtonFormField<int>(
                      // 今選択されている値（＝選択状態を保持する変数）を指定
                      // テキストボックスとcontrollerの紐づけの書き方が大分違うので戸惑うが、ドロップダウンはコントローラーがないのでこれで覚えるしかない
                      value: vm.selectedWorkTypeKey,
                      // entries.map：キー（int）と値（String）両方
                      // values.map：value（値）だけ
                      items: BlackboardSettingModel.workTypeOptions.entries.map((entry) {
                        return DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: vm.updateWorkType,
                      decoration: InputDecoration(hintText: '選択してください'),
                      validator: (value) =>
                      Validators.selectRequired(value, label: fieldLabels['forest']!)
                    ),
                    SizedBox(height: 16),

                    Text(fieldLabels['forest']!),
                    TextFormField(
                      controller: vm.forestController,
                      decoration: InputDecoration(hintText: '例：1-2'),
                      validator: (value) =>
                      Validators.required(value, label: fieldLabels['forest']!) ??
                          Validators.maxLength(value, 30, label: fieldLabels['forest']!),
                    ),
                    SizedBox(height: 24),

                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          // フォームのバリデーションがOKならtrue
                          // また万が一nullならfalseにするという条件
                          final isValid = _formKey.currentState?.validate() ?? false;

                          if(isValid){
                            final bool result = await vm.saveData();
                            // 保存完了後のトースト(下から出てくるポップ）表示
                            //
                            // 警告対応：Don't use BuildContexts across async gaps
                            // 非同期処理（await）のあとに context を使うとアプリがクラッシュする可能性がある という警告
                            // 非同期処理のあとで context を使う前に、ウィジェットがまだ生きているかをif (context.mounted)で確認することで回避
                            //
                            // ちなみにmounted は StatefulWidget でもつかえる「ウィジェットがまだ画面上に存在しているか？」を示すプロパティです。
                            // 今回はbuilder: (context, vm, _)のcontextをつかっています
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result ? '保存しました' : '保存に失敗しました')),
                              );
                            }
                            return;
                          }else{
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('入力に不備があります')),
                              );
                            }
                            return;
                          }
                        },
                        child: Text('保存'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
