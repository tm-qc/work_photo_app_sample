処理関数をまとめたクラス

<xxx_service>.dart

## メソッド書き分け補足

基本的にサービスにロジックを集約するが、以下の書き分けでViewModelにメソッドを書く場合もある。

UI参照する処理 → ViewModel
UI参照しない処理 → Service

※ServiceでUI参照するとState(状態管理)の観点で不整合だったり、複雑化する傾向がある

// これらだけならService
- File操作
- API通信
- SharedPreferences
- 純粋な計算処理
- ハードウェア制御

// これらが含まれたらViewModel
- 状態管理notifyListeners()
- GlobalKey
- BuildContext  
- RenderObject
- Widget系のクラス
- UI状態（position, size, isDragging等）

結局迷うと思うし、個々に違うかもだし、コード書くだけでも頭使うので、間違っても仕方ない内容ではある