処理関数をまとめたクラス

基本的にサービスにロジックを集約するが、
「UI層から直接呼ばれる処理」は状態管理でnotifyListeners()などが必要なので、ViewModelにメソッドを書く場合もある

<xxx_service>.dart