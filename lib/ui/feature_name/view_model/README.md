ページの状態管理State系を定義するクラスファイルを置く

基本的にサービスの処理を参照するが、
「UI層から直接呼ばれる処理」は状態管理でnotifyListeners()などが必要なので、ViewModelにメソッドを書く場合もある

<xxx_view_model>.dart